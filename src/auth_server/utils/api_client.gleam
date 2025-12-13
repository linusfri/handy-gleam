import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/json
import gleam/string

pub fn send_request(request: request.Request(String)) -> Result(Dynamic, String) {
  case httpc.send(request) {
    Ok(res) ->
      case res.status {
        200 ->
          case json.parse(res.body, decode.dynamic) {
            Ok(json_data) -> Ok(json_data)
            Error(_) -> Error("Failed to parse JSON response")
          }
        status -> Error("HTTP " <> int.to_string(status))
      }
    Error(err) -> {
      Error(string.inspect(err))
    }
  }
}
