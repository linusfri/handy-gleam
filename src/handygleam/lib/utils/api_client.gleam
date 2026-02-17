import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/result
import gleam/string
import handygleam/lib/models/error/app_error.{
  type AppError, AppError, ExternalApi,
}
import handygleam/lib/utils/logger

pub fn send_request(
  request: request.Request(String),
) -> Result(response.Response(String), AppError) {
  httpc.send(request)
  |> result.map_error(fn(err) {
    let error_msg = "HTTP request failed: " <> string.inspect(err)
    logger.log_error_with_context("api_client:send_request", error_msg)
    AppError(error: ExternalApi, message: error_msg)
  })
}
