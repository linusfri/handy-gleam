import auth_server/config.{config}
import auth_server/web
import gleam/http.{Get, Post}
import gleam/http/request
import gleam/httpc
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import gleam/uri
import glow_auth.{type Client, Client}
import glow_auth/token_request.{DefaultScope, RequestBody, client_credentials}
import glow_auth/uri/uri_builder.{RelativePath}
import wisp.{type Request, type Response}

pub type LoginFormData {
  LoginFormData(
    client_id: String,
    client_secret: String,
    grant_type: String,
    password: String,
    username: String,
    request_body: Option(String),
  )
}

pub fn handle_request(req: Request) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    [] -> home_page(req)
    ["login"] -> login(req)
    _ -> wisp.ok()
  }
}

fn home_page(req: Request) -> Response {
  use <- wisp.require_method(req, Get)

  wisp.ok()
  |> wisp.html_body("App working")
}

fn send_request(request: request.Request(String)) -> Result(Response, Response) {
  case httpc.send(request) {
    Ok(res) ->
      case res.status {
        200 -> Ok(wisp.json_response(res.body, res.status))
        _ -> Error(wisp.json_response(res.body, res.status))
      }
    Error(err) -> {
      echo err
      Error(wisp.json_response("Internal server error", 500))
    }
  }
}

fn build_login_request(form_data: LoginFormData) -> request.Request(String) {
  let client = create_client(form_data.client_id, form_data.client_secret)
  let token_endpoint = RelativePath("token")

  client_credentials(client, token_endpoint, RequestBody, DefaultScope)
  |> request.set_body(option.unwrap(form_data.request_body, ""))
}

fn build_request_body(form: wisp.FormData) {
  list.fold(form.values, "", fn(acc, name_value) {
    name_value.0 <> "=" <> name_value.1 <> "&" <> acc
  })
  |> string.drop_end(1)
}

fn login(req: Request) {
  use <- wisp.require_method(req, Post)
  use form <- wisp.require_form(req)

  case form.values {
    [
      #("client_id", client_id),
      #("client_secret", client_secret),
      #("grant_type", grant_type),
      #("password", password),
      #("username", username),
    ] -> {
      let request_body = build_request_body(form)
      let form_data =
        LoginFormData(
          client_id,
          client_secret,
          grant_type,
          password,
          username,
          Some(request_body),
        )
      let login_request = build_login_request(form_data)
      case send_request(login_request) {
        Ok(res) -> res
        Error(err) -> err
      }
    }
    _ -> wisp.json_response("Bad request", 400)
  }
}

fn create_client(client_id: String, client_secret: String) -> Client(body) {
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

  Client(id: client_id, secret: client_secret, site: site)
}
