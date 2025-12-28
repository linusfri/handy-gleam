import auth_server/lib/utils/logger
import gleam/dynamic/decode
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/json
import gleam/string
import wisp

pub fn send_request(request: request.Request(String)) {
  case httpc.send(request) {
    Ok(res) ->
      case res.status, res.body {
        200, _ ->
          case json.parse(res.body, decode.dynamic) {
            Ok(json_data) -> Ok(json_data)
            Error(err) -> {
              logger.log_error(err)
              Error(wisp.json_response(
                "Failed to parse JSON response: " <> string.inspect(err),
                500,
              ))
            }
          }
        status, body -> {
          logger.log_error(int.to_string(status) <> " | " <> body)
          Error(wisp.json_response(body, status))
        }
      }
    Error(err) -> {
      logger.log_error(err)
      Error(wisp.json_response(string.inspect(err), 500))
    }
  }
}
