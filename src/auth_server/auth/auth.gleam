import auth_server/config.{config}
import auth_server/utils/api_client
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/http.{Post}
import gleam/http/request as http_request
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam/uri
import glow_auth.{type Client, Client}
import glow_auth/token_request.{DefaultScope, RequestBody, client_credentials}
import glow_auth/uri/uri_builder.{RelativePath}
import wisp.{type Request}

pub type LoginFormData {
  LoginFormData(
    client_id: String,
    grant_type: String,
    password: String,
    username: String,
    device_name: String,
    body: List(#(String, String)),
  )
}

pub type TokenResponse {
  TokenResponse(
    access_token: String,
    expires_in: Int,
    refresh_expires_in: Int,
    refresh_token: String,
    token_type: String,
    not_before_policy: Int,
    session_state: String,
    scope: String,
  )
}

pub type LoginResponse {
  LoginResponse(token: TokenResponse, user: User)
}

pub type User {
  User(
    sub: String,
    email_verified: Bool,
    name: String,
    preferred_username: String,
    given_name: String,
    family_name: String,
    email: String,
  )
}

fn login_form_decoder(form_data: Dynamic) {
  let login_form_decoder = {
    use password <- decode.field("password", decode.string)
    use username <- decode.field("username", decode.string)
    use device_name <- decode.field("device_name", decode.string)
    let client_id = "auth-server"
    let grant_type = "password"

    let body = [
      #("client_id", client_id),
      #("grant_type", grant_type),
      #("password", password),
      #("username", username),
    ]

    decode.success(LoginFormData(
      client_id:,
      grant_type:,
      device_name:,
      password:,
      username:,
      body:,
    ))
  }

  decode.run(form_data, login_form_decoder)
}

fn token_response_decoder(json_data: Dynamic) {
  let token_decoder = {
    use access_token <- decode.field("access_token", decode.string)
    use expires_in <- decode.field("expires_in", decode.int)
    use refresh_expires_in <- decode.field("refresh_expires_in", decode.int)
    use refresh_token <- decode.field("refresh_token", decode.string)
    use token_type <- decode.field("token_type", decode.string)
    use not_before_policy <- decode.field("not-before-policy", decode.int)
    use session_state <- decode.field("session_state", decode.string)
    use scope <- decode.field("scope", decode.string)

    decode.success(TokenResponse(
      access_token: access_token,
      expires_in: expires_in,
      refresh_expires_in: refresh_expires_in,
      refresh_token: refresh_token,
      token_type: token_type,
      not_before_policy: not_before_policy,
      session_state: session_state,
      scope: scope,
    ))
  }

  decode.run(json_data, token_decoder)
}

fn user_decoder(json_data: Dynamic) {
  let user_decoder = {
    use sub <- decode.field("sub", decode.string)
    use email_verified <- decode.field("email_verified", decode.bool)
    use name <- decode.field("name", decode.string)
    use preferred_username <- decode.field("preferred_username", decode.string)
    use given_name <- decode.field("given_name", decode.string)
    use family_name <- decode.field("family_name", decode.string)
    use email <- decode.field("email", decode.string)

    decode.success(User(
      sub: sub,
      email_verified: email_verified,
      name: name,
      preferred_username: preferred_username,
      given_name: given_name,
      family_name: family_name,
      email: email,
    ))
  }

  decode.run(json_data, user_decoder)
}

fn token_response_encoder(token: TokenResponse) -> json.Json {
  json.object([
    #("access_token", json.string(token.access_token)),
    #("expires_in", json.int(token.expires_in)),
    #("refresh_expires_in", json.int(token.refresh_expires_in)),
    #("refresh_token", json.string(token.refresh_token)),
    #("token_type", json.string(token.token_type)),
    #("not_before_policy", json.int(token.not_before_policy)),
    #("session_state", json.string(token.session_state)),
    #("scope", json.string(token.scope)),
  ])
}

fn login_response_encoder(login_response: LoginResponse) -> json.Json {
  json.object([
    #("token", token_response_encoder(login_response.token)),
    #("user", user_encoder(login_response.user)),
  ])
}

fn user_encoder(user: User) -> json.Json {
  json.object([
    #("sub", json.string(user.sub)),
    #("email_verified", json.bool(user.email_verified)),
    #("name", json.string(user.name)),
    #("preferred_username", json.string(user.preferred_username)),
    #("given_name", json.string(user.given_name)),
    #("family_name", json.string(user.family_name)),
    #("email", json.string(user.email)),
  ])
}

fn get_default_site_uri() {
  uri.Uri(
    scheme: None,
    userinfo: None,
    host: Some(config().auth_endpoint),
    port: None,
    path: "",
    query: None,
    fragment: None,
  )
}

fn create_client(client_id: String) -> Client(body) {
  let site = get_default_site_uri()

  Client(id: client_id, secret: "None", site: site)
}

pub fn build_login_request(
  login_form_data: LoginFormData,
) -> http_request.Request(String) {
  let client = create_client(login_form_data.client_id)
  let token_endpoint = RelativePath("token")
  let request_body = build_request_body(login_form_data.body)

  client_credentials(client, token_endpoint, RequestBody, DefaultScope)
  |> http_request.set_body(request_body)
}

pub fn build_request_body(form_values: List(#(String, String))) {
  list.fold(form_values, "", fn(acc, name_value) {
    name_value.0 <> "=" <> name_value.1 <> "&" <> acc
  })
  |> string.drop_end(1)
}

fn get_user(access_token: String) {
  let site_uri = get_default_site_uri()
  let user_info_request =
    http_request.Request(
      method: http.Get,
      headers: [#("Authorization", "Bearer " <> access_token)],
      body: "",
      scheme: http.Https,
      host: config().auth_endpoint,
      port: site_uri.port,
      path: "/userinfo",
      query: site_uri.query,
    )

  api_client.send_request(user_info_request)
}

fn build_login_response(form_data: LoginFormData) {
  let login_request = build_login_request(form_data)

  let token_response = case api_client.send_request(login_request) {
    Ok(res) ->
      case token_response_decoder(res) {
        Ok(token_response) -> Ok(token_response)
        Error(_) -> Error(wisp.json_response("Could not decode token", 500))
      }
    Error(wisp_error) -> Error(wisp_error)
  }

  use token <- result.try(token_response)
  use user_response <- result.try(get_user(token.access_token))

  case user_decoder(user_response) {
    Ok(user) -> {
      let login_response = LoginResponse(token: token, user: user)
      let json_body = login_response_encoder(login_response)
      Ok(wisp.json_response(json.to_string(json_body), 200))
    }
    Error(_) -> Error(wisp.json_response("Failed to decode user info", 500))
  }
}

pub fn login(req: Request) {
  use <- wisp.require_method(req, Post)
  use json_body <- wisp.require_json(req)

  case login_form_decoder(json_body) {
    Ok(form_data) ->
      case build_login_response(form_data) {
        Ok(response) -> response
        Error(error_response) -> error_response
      }
    Error(_) -> wisp.json_response("Invalid JSON body", 400)
  }
}

pub fn get_current_user(req) {
  use <- wisp.require_method(req, http.Get)
  let token = req |> http_request.get_header("Authorization")

  let token = case token {
    Ok(auth_header) -> {
      case string.split(auth_header, " ") {
        ["Bearer", token] | ["bearer", token] -> token
        _ -> auth_header
      }
    }
    _ -> ""
  }

  case get_user(token) {
    Ok(user_data) -> {
      case user_decoder(user_data) {
        Ok(user) -> {
          let user_json = user_encoder(user)
          wisp.json_response(json.to_string(user_json), 200)
        }
        Error(_) -> wisp.json_response("Failed to decode user", 500)
      }
    }
    Error(wisp_error) -> wisp_error
  }
}
