import auth_server/config.{config}
import auth_server/database/database
import auth_server/lib/utils/hot_reload.{enable_hot_reload}
import auth_server/router
import auth_server/web
import gleam/erlang/process
import mist
import pog
import wisp
import wisp/wisp_mist

pub fn main() {
  wisp.configure_logger()

  let db_name = process.new_name("auth_server")
  let assert Ok(_) = database.start_application_supervisor(db_name)
  let db = pog.named_connection(db_name)

  let ctx = web.Context(db)

  let _ = enable_hot_reload()
  let handler = router.handle_request(_, ctx)

  let assert Ok(_) =
    wisp_mist.handler(handler, config().secret_key)
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(8000)
    |> mist.start

  process.sleep_forever()
}
