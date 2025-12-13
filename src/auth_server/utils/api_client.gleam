import gleam/http/request
import gleam/httpc
import wisp.{type Response}

pub fn send_request(
  request: request.Request(String),
) -> Result(Response, Response) {
  case httpc.send(request) {
    Ok(res) ->
      case res.status {
        200 -> Ok(wisp.json_response(res.body, res.status))
        _ -> Error(wisp.json_response(res.body, res.status))
      }
    Error(_) -> {
      Error(wisp.json_response("Internal server error", 500))
    }
  }
}
