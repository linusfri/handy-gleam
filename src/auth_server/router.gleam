import auth_server/web
import gleam/http.{Get}
import gleam/string_tree
import wisp.{type Request, type Response}

pub fn handle_request(req: Request) -> Response {
  use req <- web.middleware(req)

  // Wisp doesn't have a special router abstraction, instead we recommend using
  // regular old pattern matching. This is faster than a router, is type safe,
  // and means you don't have to learn or be limited by a special DSL.
  case wisp.path_segments(req) {
    // This matches `/`.
    [] -> home_page(req)
    _ -> wisp.ok()
  }
}

fn home_page(req: Request) -> Response {
  use <- wisp.require_method(req, Get)

  let html = string_tree.from_string("App working")
  wisp.ok()
  |> wisp.html_body(html)
}
