import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/result
import gleam/string
import handygleam/lib/utils/logger

pub fn send_request(
  request: request.Request(String),
) -> Result(response.Response(String), String) {
  httpc.send(request)
  |> result.map_error(fn(err) {
    let error_msg = "HTTP request failed: " <> string.inspect(err)
    logger.log_error(error_msg)
    error_msg
  })
}
