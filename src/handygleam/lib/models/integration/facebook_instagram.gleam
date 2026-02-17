import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import handygleam/config.{config}
import handygleam/global_types
import handygleam/lib/models/auth/auth_utils
import handygleam/lib/models/error/app_error.{
  type AppError, AppError, DbError, ExternalApi, Internal, NotFound,
  from_transaction,
}
import handygleam/lib/models/file/file_types
import handygleam/lib/models/file_system/file_system
import handygleam/lib/models/integration/integration_transform
import handygleam/lib/models/integration/integration_types
import handygleam/lib/models/integration/integration_utils
import handygleam/lib/models/product/product_types.{type FacebookProduct}
import handygleam/lib/models/user/user_transform
import handygleam/lib/models/user/user_types
import handygleam/lib/utils/api_client
import handygleam/lib/utils/logger
import handygleam/sql
import pog
import wisp

pub fn initiate_login(
  req: request.Request(wisp.Connection),
) -> Result(String, AppError) {
  let token = auth_utils.get_session_token(req)

  let request =
    request.Request(
      method: http.Get,
      headers: [],
      body: "",
      scheme: http.Https,
      host: "www.facebook.com",
      port: None,
      path: "/dialog/oauth",
      query: None,
    )
    |> request.set_query([
      #("client_id", config().facebook_app_id),
      #("redirect_uri", config().facebook_redirect_uri),
      #("response_type", "code"),
      #("state", token),
      #(
        "scope",
        "pages_show_list,business_management,instagram_basic,instagram_manage_comments,instagram_content_publish,instagram_manage_messages,pages_read_engagement,pages_manage_metadata,pages_read_user_content,pages_manage_posts,pages_manage_engagement",
      ),
    ])

  use res <- result.try(api_client.send_request(request))

  case res.status {
    status if status > 300 && status < 400 -> {
      list.key_find(res.headers, "location")
      |> result.map_error(fn(_) {
        AppError(
          error: ExternalApi,
          message: "Did not get a correct redirect response from facebook",
        )
      })
    }
    _ ->
      Error(AppError(
        error: ExternalApi,
        message: "Unexpected response: " <> res.body,
      ))
  }
}

pub fn exchange_code_for_token(
  code: String,
) -> Result(integration_types.FacebookToken, AppError) {
  let token_request =
    request.Request(
      method: http.Get,
      headers: [],
      body: "",
      scheme: http.Https,
      host: config().facebook_base_url,
      port: None,
      path: "/oauth/access_token",
      query: None,
    )
    |> request.set_query([
      #("client_id", config().facebook_app_id),
      #("client_secret", config().facebook_app_secret),
      #("redirect_uri", config().facebook_redirect_uri),
      #("fields", "expires_in,access_token,token_type"),
      #("code", code),
    ])

  use response <- result.try(api_client.send_request(token_request))

  case response.status {
    status if status >= 200 && status < 300 -> {
      use json_data <- result.try(
        json.parse(response.body, decode.dynamic)
        |> result.map_error(fn(err) {
          logger.log_error(err)
          AppError(
            error: ExternalApi,
            message: "Failed to parse Facebook token response",
          )
        }),
      )

      integration_transform.facebook_token_decoder(json_data)
      |> result.map_error(fn(err) {
        logger.log_error_with_context(
          "facebook_instagram:exchange_code_for_token",
          err,
        )
        AppError(error: ExternalApi, message: "Failed to decode Facebook token")
      })
    }
    _ ->
      Error(AppError(
        error: ExternalApi,
        message: "Facebook API error: " <> response.body,
      ))
  }
}

pub fn get_facebook_user(
  ctx: global_types.Context,
  user: user_types.User,
  integration: sql.IntegrationPlatform,
) {
  use facebook_token <- result.try(
    integration_utils.get_integration_token(ctx, user, integration)
    |> result.map_error(fn(error) {
      logger.log_error_with_context(
        "integration_service:get_facebook_user",
        error,
      )
      AppError(
        error: error.error,
        message: "Could not get facebook token from database.",
      )
    }),
  )

  let user_request =
    request.Request(
      method: http.Get,
      headers: [],
      body: "",
      scheme: http.Https,
      host: config().facebook_base_url,
      port: None,
      path: "/me",
      query: Some("access_token=" <> facebook_token.access_token),
    )

  let facebook_user = {
    use user_response <- result.try(case api_client.send_request(user_request) {
      Ok(response) -> Ok(response)
      Error(error_response) -> Error(error_response)
    })

    use dynamic_user <- result.try(
      json.parse(user_response.body, decode.dynamic)
      |> result.map_error(fn(error) {
        logger.log_error_with_context(
          "facebook_instagram:get_facebook_user",
          error,
        )
        AppError(
          error: ExternalApi,
          message: "Could not get user from facebook api response",
        )
      }),
    )

    use user <- result.try(
      user_transform.facebook_user_decoder(dynamic_user)
      |> result.map_error(fn(error) {
        logger.log_error_with_context(
          "facebook_instagram:get_facebook_user",
          error,
        )
        AppError(
          error: ExternalApi,
          message: "Failed to decode facebook user from response",
        )
      }),
    )

    Ok(user)
  }

  case facebook_user {
    Ok(facebook_user) -> Ok(facebook_user)
    Error(error) -> Error(error)
  }
}

pub fn get_current_facebook_user_pages(
  ctx: global_types.Context,
  user: user_types.User,
  integration: sql.IntegrationPlatform,
) -> Result(integration_types.FacebookPagesResponse, AppError) {
  use facebook_token <- result.try(integration_utils.get_integration_token(
    ctx,
    user,
    integration,
  ))

  let user_pages_request =
    request.Request(
      method: http.Get,
      headers: [],
      body: "",
      scheme: http.Https,
      host: config().facebook_base_url,
      port: None,
      path: "/me/accounts",
      query: Some("access_token=" <> facebook_token.access_token),
    )

  use user_pages_response <- result.try(
    case api_client.send_request(user_pages_request) {
      Ok(response) -> Ok(response)
      Error(error_response) -> Error(error_response)
    },
  )

  use dynamic_pages <- result.try(
    json.parse(user_pages_response.body, decode.dynamic)
    |> result.map_error(fn(error) {
      logger.log_error_with_context(
        "facebook_instagram:get_current_facebook_user_pages",
        error,
      )
      AppError(
        error: ExternalApi,
        message: "Could not parse facebook pages response",
      )
    }),
  )

  integration_transform.facebook_pages_response_decoder(dynamic_pages)
  |> result.map_error(fn(error) {
    logger.log_error_with_context(
      "facebook_instagram:get_current_facebook_user_pages",
      error,
    )
    AppError(
      error: ExternalApi,
      message: "Failed to decode facebook pages from response",
    )
  })
}

pub fn fetch_and_cache_facebook_pages(
  ctx: global_types.Context,
  user: user_types.User,
  integration: sql.IntegrationPlatform,
) -> Result(integration_types.FacebookPagesResponse, AppError) {
  use pages_response <- result.try(get_current_facebook_user_pages(
    ctx,
    user,
    integration,
  ))

  use _saved_resources <- result.try(
    integration_utils.save_platform_resources(
      ctx,
      user,
      integration,
      pages_response.data,
    )
    |> result.map_error(fn(error) {
      logger.log_error_with_context(
        "facebook_instagram:fetch_and_cache_facebook_pages",
        error,
      )
      AppError(
        error: DbError,
        message: "Failed to cache page resources in database",
      )
    }),
  )

  Ok(pages_response)
}

pub fn get_page_token(
  ctx: global_types.Context,
  user: user_types.User,
  integration: sql.IntegrationPlatform,
  page_id: String,
) -> Result(String, AppError) {
  use resource <- result.try(
    integration_utils.get_platform_resource(ctx, user, integration, page_id)
    |> result.map_error(fn(error) {
      logger.log_error_with_context("facebook_instagram:get_page_token", error)
      error
    }),
  )

  case resource.resource_token {
    Some(token) -> Ok(token)
    None ->
      Error(AppError(
        error: NotFound,
        message: "Page token not found for page_id: " <> page_id,
      ))
  }
}

pub fn update_or_create_post_on_page(
  ctx: global_types.Context,
  user: user_types.User,
  integration: sql.IntegrationPlatform,
  facebook_product: FacebookProduct,
) {
  use facebook_pages <- result.try(
    sql.select_product_integrations_facebook_pages(ctx.db, facebook_product.id)
    |> result.map_error(fn(err) {
      logger.log_error_with_context(
        "facebook_instagram:update_or_create_post",
        err,
      )
      AppError(
        error: DbError,
        message: "Did not find any facebook page integrations for this product",
      )
    }),
  )

  // Just pick the first one for MVP
  use facebook_page_resource <- result.try(
    list.first(facebook_pages.rows)
    |> result.map_error(fn(_) {
      AppError(
        error: NotFound,
        message: "No facebook page found for this product",
      )
    }),
  )
  let page_id = option.unwrap(facebook_page_resource.resource_id, "")

  use facebook_page_token <- result.try(get_page_token(
    ctx,
    user,
    integration,
    page_id,
  ))

  use external_image_ids <- result.try(create_or_update_files_on_page(
    ctx,
    facebook_product,
    sql.Facebook,
    page_id,
    facebook_page_token,
  ))

  // If there is an external id it means that we have created a post for this product on this page
  case facebook_page_resource.external_id {
    Some(external_id) ->
      update_post_on_page(
        facebook_product,
        external_id,
        external_image_ids,
        facebook_page_token,
      )
    None ->
      create_post_on_page(
        ctx,
        facebook_product,
        external_image_ids,
        page_id,
        facebook_page_token,
      )
  }
}

fn create_post_on_page(
  ctx: global_types.Context,
  facebook_product: FacebookProduct,
  external_image_ids: List(String),
  page_id: String,
  page_token: String,
) {
  let base_query_params = [
    #("access_token", page_token),
    #(
      "message",
      facebook_product.name
        <> "\n\n"
        <> option.unwrap(facebook_product.description, ""),
    ),
  ]

  let query_params = case external_image_ids {
    [] -> base_query_params
    external_image_ids ->
      list.append(
        base_query_params,
        integration_utils.build_facbook_media_query(external_image_ids),
      )
  }

  let create_post_request =
    request.Request(
      method: http.Post,
      headers: [],
      body: "",
      scheme: http.Https,
      host: config().facebook_base_url,
      port: None,
      path: page_id <> "/feed",
      query: None,
    )
    |> request.set_query(query_params)

  use create_post_response <- result.try(
    api_client.send_request(create_post_request)
    |> result.map_error(fn(err) {
      logger.log_error_with_context(
        "facebook_instagram:create_post_on_page",
        err,
      )
      err
    }),
  )

  let facebook_id_decoder = {
    use id <- decode.field("id", decode.string)
    decode.success(id)
  }

  use external_post_id <- result.try(
    json.parse(from: create_post_response.body, using: facebook_id_decoder)
    |> result.map_error(fn(err) {
      logger.log_error_with_context(
        "facebook_instagram:create_post_on_page",
        err,
      )
      AppError(
        error: ExternalApi,
        message: "Failed to decode returned post id from Facebook response",
      )
    }),
  )

  use _ <- result.try(
    pog.transaction(ctx.db, fn(tx) {
      sql.update_product_integration_external_id(
        tx,
        external_post_id,
        facebook_product.id,
        page_id,
      )
      |> result.map_error(fn(error) {
        logger.log_error_with_context(
          "facebook_instagram:create_post_on_page",
          error,
        )
        AppError(
          error: DbError,
          message: "Failed to update product integration in db when creating post on facebook page",
        )
      })
    })
    |> result.map_error(from_transaction),
  )

  Ok("Post created")
}

fn update_post_on_page(
  facebook_product: FacebookProduct,
  external_id: String,
  external_image_ids: List(String),
  page_token: String,
) {
  let base_query_params = [
    #("access_token", page_token),
    #(
      "message",
      facebook_product.name
        <> "\n\n"
        <> option.unwrap(facebook_product.description, ""),
    ),
  ]

  let query_params = case external_image_ids {
    [] -> base_query_params
    external_image_ids ->
      list.append(
        base_query_params,
        integration_utils.build_facbook_media_query(external_image_ids),
      )
  }

  let update_post_request =
    request.Request(
      method: http.Post,
      headers: [],
      body: "",
      scheme: http.Https,
      host: config().facebook_base_url,
      port: None,
      path: external_id,
      query: None,
    )
    |> request.set_query(query_params)

  let res =
    api_client.send_request(update_post_request)
    |> result.map(fn(_) { "Post updated" })

  res
}

fn create_or_update_files_on_page(
  ctx: global_types.Context,
  facebook_product: FacebookProduct,
  platform: sql.IntegrationPlatform,
  page_id: String,
  page_token: String,
) -> Result(List(String), AppError) {
  let image_ids =
    facebook_product.images
    |> list.filter_map(fn(image) { image.id |> option.to_result(Nil) })

  let files_to_create = facebook_product.images

  // There is a file_integration table to keep track of which files are already created.
  // But facebook seems to handle creation and deletion of images without me mapping the external and internal image ids.
  // This might not be the case with other integrations so the table remains and is written to.
  use _ <- result.try(
    upload_files_to_page(ctx, files_to_create, platform, page_id, page_token)
    |> result.map_error(fn(error) {
      logger.log_error_with_context(
        "facebook_instagram:create_files_on_page",
        error,
      )
      AppError(
        error: DbError,
        message: "Failed to upload and save files in transaction",
      )
    }),
  )

  get_all_files_for_page_and_platform(ctx, image_ids, platform, page_id)
}

fn get_all_files_for_page_and_platform(
  ctx: global_types.Context,
  file_ids: List(Int),
  platform: sql.IntegrationPlatform,
  page_id: String,
) {
  use all_file_integrations <- result.try(
    pog.transaction(ctx.db, fn(tx) {
      use integrations <- result.try(
        sql.select_file_integrations_by_files_and_resource(
          tx,
          file_ids,
          platform,
          page_id,
        )
        |> result.map_error(fn(err) {
          AppError(
            error: DbError,
            message: "Could not query file integrations after upload | "
              <> string.inspect(err),
          )
        }),
      )

      Ok(integrations)
    })
    |> result.map_error(from_transaction),
  )

  Ok(
    all_file_integrations.rows
    |> list.filter(fn(file_integration) {
      option.is_some(file_integration.external_id)
    })
    |> list.map(fn(file_integration) {
      option.unwrap(file_integration.external_id, "")
    }),
  )
}

fn upload_files_to_page(
  ctx: global_types.Context,
  files: List(file_types.File),
  platform: sql.IntegrationPlatform,
  page_id: String,
  page_token: String,
) -> Result(Nil, AppError) {
  files
  |> list.try_each(fn(file) {
    let upload_request =
      request.Request(
        method: http.Post,
        headers: [],
        body: "",
        scheme: http.Https,
        host: config().facebook_base_url,
        port: None,
        path: page_id <> "/photos",
        query: None,
      )
      |> request.set_query([
        #("access_token", page_token),
        #("url", file_system.file_url_from_file(file)),
        #("published", "false"),
        // To not publish photos on upload
      ])

    use upload_response <- result.try(
      api_client.send_request(upload_request)
      |> result.map_error(fn(err) {
        logger.log_error_with_context(
          "facebook_instagram:upload_files_to_page",
          err,
        )
        AppError(
          error: ExternalApi,
          message: "Failed to upload photo to Facebook",
        )
      }),
    )

    let facebook_id_decoder = {
      use id <- decode.field("id", decode.string)
      decode.success(id)
    }

    use external_id <- result.try(
      json.parse(from: upload_response.body, using: facebook_id_decoder)
      |> result.map_error(fn(err) {
        logger.log_error_with_context(
          "facebook_instagram:upload_files_to_page",
          err,
        )
        AppError(
          error: ExternalApi,
          message: "Failed to decode photo id from Facebook response",
        )
      }),
    )

    // Save the file integration to database
    use file_id <- result.try(
      file.id
      |> option.to_result(AppError(error: Internal, message: "File has no ID")),
    )

    // TODO: Redo this query to not run in a loop.
    use _ <- result.try(
      pog.transaction(ctx.db, fn(tx) {
        sql.update_or_create_file_integration(
          tx,
          file_id,
          platform,
          page_id,
          external_id,
          json.null(),
        )
        |> result.map_error(fn(error) {
          logger.log_error_with_context(
            "facebook_instagram:upload_files_to_page",
            error,
          )
          AppError(
            error: DbError,
            message: "Failed to save file integration to database",
          )
        })
      })
      |> result.map_error(from_transaction),
    )

    Ok(Nil)
  })
}
