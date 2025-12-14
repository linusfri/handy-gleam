import auth_server/auth/types.{
  type LoginResponse, type TokenResponse, type User, LoginFormData,
  TokenResponse, User,
}
import auth_server/config.{config}
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleam/uri

pub fn get_default_site_uri() {
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

pub fn build_request_body(form_values: List(#(String, String))) {
  list.fold(form_values, "", fn(acc, name_value) {
    name_value.0 <> "=" <> name_value.1 <> "&" <> acc
  })
  |> string.drop_end(1)
}

// Decoders and encoders
pub fn login_form_decoder(form_data: Dynamic) {
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

pub fn token_response_decoder(json_data: Dynamic) {
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

pub fn user_decoder(json_data: Dynamic) {
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

pub fn token_response_encoder(token: TokenResponse) -> json.Json {
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

pub fn login_response_encoder(login_response: LoginResponse) -> json.Json {
  json.object([
    #("token", token_response_encoder(login_response.token)),
    #("user", user_encoder(login_response.user)),
  ])
}

pub fn user_encoder(user: User) -> json.Json {
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
