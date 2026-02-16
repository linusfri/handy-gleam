import gleam/http/request as http_request
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleam/uri
import handygleam/config.{config}

pub fn get_default_auth_uri() {
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

pub fn get_default_admin_url() {
  uri.Uri(
    scheme: None,
    userinfo: None,
    host: Some(config().admin_endpoint),
    port: None,
    path: "",
    query: None,
    fragment: None,
  )
}

pub fn get_session_token(req) {
  let token = http_request.get_header(req, "Authorization")

  case token {
    Ok(auth_header) -> {
      case string.split(auth_header, " ") {
        ["Bearer", token] | ["bearer", token] -> token
        _ -> auth_header
      }
    }
    _ -> ""
  }
}

pub fn build_url_encoded_request_body(form_values: List(#(String, String))) {
  list.fold(form_values, "", fn(acc, name_value) {
    name_value.0 <> "=" <> name_value.1 <> "&" <> acc
  })
  |> string.drop_end(1)
}
