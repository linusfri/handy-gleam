import gleam/io
import radiate

pub fn enable_hot_reload() {
  radiate.new()
  |> radiate.add_dir("src")
  |> radiate.on_reload(fn(_state, path) {
    io.println("Change in " <> path <> ", reloading!")
  })
  |> radiate.start()
}
