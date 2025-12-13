import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/http/request
import gleam/httpc
import gleam/json

pub fn send_request(request: request.Request(String)) -> Result(Dynamic, String) {
  case httpc.send(request) {
    Ok(res) ->
      case res.status {
        200 ->
          case json.parse(res.body, decode.dynamic) {
            Ok(json_data) -> Ok(json_data)
            Error(_) -> Error("Failed to parse JSON response")
          }
        _ -> Error(res.body)
      }
    Error(_) -> {
      Error("Internal server error")
    }
  }
}
