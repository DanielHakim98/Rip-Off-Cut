import gleam/io
import glint/flag
import glint
import argv

const delimiter = "delimiter"

fn delimiter_flag() -> flag.FlagBuilder(String) {
  flag.string()
  |> flag.default("tab")
  |> flag.description("use DELIM instead of TAB for field delimiter")
}

fn delimiter_callback(input: glint.CommandInput) -> Nil {
  let assert Ok(v) = flag.get_string(from: input.flags, for: delimiter)
  case v {
    " " -> "space"
    "," -> "comma"
    "|" -> "pipe"
    ";" -> "semicolon"
    "tab" -> "tab"
    _ -> "unsupported delimiter"
  }
  |> io.println
}


pub fn main() {
  glint.new()
  |> glint.with_name("cut")
  |> glint.add(
    at: [],
    do: glint.command(delimiter_callback)
      |> glint.flag(delimiter, delimiter_flag())
      |> glint.description(
        "Print selected parts of lines from each FILE to standard output.\n\nWith no FILE, or when FILE is -, read standard input."),
  )
  |> glint.run(argv.load().arguments)
}
