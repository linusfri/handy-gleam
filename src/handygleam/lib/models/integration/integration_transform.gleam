import gleam/dynamic
import gleam/dynamic/decode
import gleam/json
import handygleam/lib/models/integration/integration_types.{
  type FacebookPage, type FacebookPagesResponse, type FacebookToken,
  FacebookPage, FacebookPagesResponse, FacebookToken,
}

//---- Tokens
pub fn facebook_token_to_json(facebook_token: FacebookToken) -> json.Json {
  let FacebookToken(access_token:, token_type:) = facebook_token
  json.object([
    #("access_token", json.string(access_token)),
    #("token_type", json.string(token_type)),
  ])
}

pub fn facebook_token_decoder(token_data: dynamic.Dynamic) {
  let facebook_token_decoder = {
    use access_token <- decode.field("access_token", decode.string)
    use token_type <- decode.field("token_type", decode.string)
    decode.success(FacebookToken(access_token:, token_type:))
  }

  decode.run(token_data, facebook_token_decoder)
}

//---- Pages
pub fn facebook_pages_response_to_json(
  facebook_pages_response: FacebookPagesResponse,
) -> json.Json {
  let FacebookPagesResponse(data:) = facebook_pages_response
  json.object([
    #("data", json.array(data, facebook_page_to_json)),
  ])
}

pub fn facebook_pages_response_decoder(dynamic_pages: dynamic.Dynamic) {
  let facebook_pages_response_decoder = {
    use data <- decode.field("data", decode.list(facebook_page_decoder()))
    decode.success(FacebookPagesResponse(data:))
  }

  decode.run(dynamic_pages, facebook_pages_response_decoder)
}

pub fn facebook_page_to_json(facebook_page: FacebookPage) -> json.Json {
  let FacebookPage(access_token:, id:, name:) = facebook_page
  json.object([
    #("access_token", json.string(access_token)),
    #("id", json.string(id)),
    #("name", json.string(name)),
  ])
}

pub fn facebook_page_decoder() -> decode.Decoder(FacebookPage) {
  use access_token <- decode.field("access_token", decode.string)
  use id <- decode.field("id", decode.string)
  use name <- decode.field("name", decode.string)
  decode.success(FacebookPage(access_token:, id:, name:))
}
