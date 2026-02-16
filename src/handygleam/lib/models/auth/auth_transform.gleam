import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/json
import handygleam/lib/models/auth/auth_types.{
  type LoginResponse, type TokenResponse, LoginFormData, TokenResponse,
}
import handygleam/lib/models/user/user_transform

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

pub fn refresh_token_request_decoder(json_data: Dynamic) {
  let refresh_token_decoder = {
    use refresh_token <- decode.field("refresh_token", decode.string)
    let client_id = "auth-server"

    decode.success(auth_types.RefreshTokenRequest(refresh_token:, client_id:))
  }

  decode.run(json_data, refresh_token_decoder)
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
    #("user", user_transform.user_encoder(login_response.user)),
  ])
}
