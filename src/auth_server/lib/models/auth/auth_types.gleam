import auth_server/lib/models/user/user_types.{type User}

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

pub type RefreshTokenRequest {
  RefreshTokenRequest(client_id: String, refresh_token: String)
}
