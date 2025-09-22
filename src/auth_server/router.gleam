import auth_server/config.{config}
import auth_server/web
import gleam/http.{Get, Post}
import gleam/http/request
import gleam/httpc
import gleam/list
import gleam/result
import gleam/string
import wisp.{type Request, type Response}

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

fn login(req: Request) -> Response {
  use <- wisp.require_method(req, Post)
  use form <- wisp.require_form(req)

  let request_body =
    list.fold(form.values, "", fn(acc, form_value) {
      form_value.0 <> "=" <> form_value.1 <> "&" <> acc
    })
    |> string.drop_end(1)

  let request =
    request.to(config().auth_endpoint <> "/token")
    |> result.map(fn(req) {
      request.set_method(req, http.Post)
      |> request.set_header("content-Type", "application/x-www-form-urlencoded")
      |> request.set_body(request_body)
    })

  let response =
    result.try(request, fn(request) {
      case httpc.send(request) {
        Ok(res) ->
          case res.status {
            200 | 401 -> Ok(wisp.json_response(res.body, res.status))
            _ -> Error(Nil)
          }
        Error(_) -> Error(Nil)
      }
    })

  case response {
    Ok(res) ->
      case res.status {
        200 -> {
          // Actually log in user, add to db and store token there. 
          res
        }
        _ -> res
      }
    Error(_) -> wisp.json_response("Login failed", 400)
  }
}
