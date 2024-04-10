import gleam/io
import glint/flag
import gleam/string
import glint
import argv

const caps = "caps"

fn caps_flag() -> flag.FlagBuilder(Bool) {
  flag.bool()
  |> flag.default(False)
  |> flag.description("Capitalize the provided name")
}

fn hello(input: glint.CommandInput) -> Nil {
  let assert Ok(caps) = flag.get_bool(from: input.flags, for: caps)

  let name = case input.args {
    [] -> "Joe"
    [name, ..] -> name
  }

  let msg = "Hello, " <> name <> "!"

  case caps {
    True -> string.uppercase(msg)
    False -> msg
  }
  |> io.println
}

pub fn main() {
  glint.new()
  |> glint.with_name("cut")
  |> glint.with_pretty_help(glint.default_pretty_help())
  |> glint.add(
    at: [],
    do: glint.command(hello)
      |> glint.flag(caps, caps_flag())
      |> glint.description("Printts Hello, <NAME>!"),
  )
  |> glint.run(argv.load().arguments)
}
