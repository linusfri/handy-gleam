import auth_server/config
import auth_server/router
import auth_server/utils/hot_reload.{enable_hot_reload}
import gleam/erlang/process
import mist
import wisp
import wisp/wisp_mist

pub fn main() {
  wisp.configure_logger()
  let config = config.get_config()

  let _ = enable_hot_reload()

  let assert Ok(_) =
    wisp_mist.handler(router.handle_request, config.secret_key)
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(8000)
    |> mist.start

  process.sleep_forever()
}
