import gleam/string
import pog
import wisp

pub type ErrorType {
  InvalidPayload
  NotFound
  Unauthorized
  Forbidden
  DbError
  ExternalApi
  Internal
}

pub type AppError {
  AppError(error: ErrorType, message: String)
}

pub fn from_transaction(error: pog.TransactionError(AppError)) -> AppError {
  case error {
    pog.TransactionQueryError(query_error) ->
      AppError(
        error: DbError,
        message: "Transaction failed | " <> string.inspect(query_error),
      )
    pog.TransactionRolledBack(inner) -> inner
  }
}

pub fn to_http_response(error: AppError) {
  case error.error {
    InvalidPayload -> wisp.json_response(error.message, 400)
    NotFound -> wisp.json_response(error.message, 404)
    Unauthorized -> wisp.json_response(error.message, 401)
    Forbidden -> wisp.json_response(error.message, 403)
    DbError -> wisp.json_response(error.message, 500)
    ExternalApi -> wisp.json_response(error.message, 502)
    Internal -> wisp.json_response(error.message, 500)
  }
}
