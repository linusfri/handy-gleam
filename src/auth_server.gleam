import auth_server/router
import envoy
import gleam/erlang/process
import gleam/io
import mist
import wisp
import wisp/wisp_mist

pub fn main() {
  wisp.configure_logger()
  let secret_key_base = case envoy.get("SECRET_KEY") {
    Ok(secret_key) -> secret_key
    Error(Nil) -> {
      io.println("Warning, a default app key is used. Set SECRET_KEY env.")
      "default"
    }
  }

  let assert Ok(_) =
    wisp_mist.handler(router.handle_request, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}
