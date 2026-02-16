import gleam/erlang/process
import gleam/otp/static_supervisor
import handygleam/config.{config}
import pog

/// Initializes database connection
pub fn start_application_supervisor(pool_name: process.Name(pog.Message)) {
  let pool_child =
    pog.default_config(pool_name)
    |> pog.host(config().pghost)
    |> pog.user("handygleam")
    |> pog.database("handygleam")
    |> pog.pool_size(15)
    |> pog.supervised

  static_supervisor.new(static_supervisor.RestForOne)
  |> static_supervisor.add(pool_child)
  |> static_supervisor.start
}
