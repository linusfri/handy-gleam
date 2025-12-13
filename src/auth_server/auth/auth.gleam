import auth_server/config.{config}
import auth_server/utils/api_client
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/http.{Post}
import gleam/http/request
import gleam/list
import gleam/option.{None, Some}
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
    body: List(#(String, String)),
  )
}

fn login_form_decoder(form_data: Dynamic) {
  let login_form_decoder = {
    use client_id <- decode.field("client_id", decode.string)
    use grant_type <- decode.field("grant_type", decode.string)
    use password <- decode.field("password", decode.string)
    use username <- decode.field("username", decode.string)

    let body = [
      #("client_id", client_id),
      #("grant_type", grant_type),
      #("password", password),
      #("username", username),
    ]

    decode.success(LoginFormData(
      client_id:,
      grant_type:,
      password:,
      username:,
      body:,
    ))
  }

  decode.run(form_data, login_form_decoder)
}

fn create_client(client_id: String) -> Client(body) {
  let site =
    uri.Uri(
      scheme: None,
      userinfo: None,
      host: Some(config().auth_endpoint),
      port: None,
      path: "",
      query: None,
      fragment: None,
    )

  Client(id: client_id, secret: "None", site: site)
}

pub fn build_login_request(
  login_form_data: LoginFormData,
) -> request.Request(String) {
  let client = create_client(login_form_data.client_id)
  let token_endpoint = RelativePath("token")
  let request_body = build_request_body(login_form_data.body)

  client_credentials(client, token_endpoint, RequestBody, DefaultScope)
  |> request.set_body(request_body)
}

pub fn build_request_body(form_values: List(#(String, String))) {
  list.fold(form_values, "", fn(acc, name_value) {
    name_value.0 <> "=" <> name_value.1 <> "&" <> acc
  })
  |> string.drop_end(1)
}

pub fn login(req: Request) {
  use <- wisp.require_method(req, Post)
  use json_body <- wisp.require_json(req)

  case login_form_decoder(json_body) {
    Ok(form_data) -> {
      let login_request = build_login_request(form_data)
      case api_client.send_request(login_request) {
        Ok(res) -> res
        Error(err) -> err
      }
    }
    Error(_) -> wisp.json_response("Invalid JSON body", 400)
  }
}
