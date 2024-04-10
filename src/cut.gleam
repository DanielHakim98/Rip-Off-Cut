import gleam/io
import gleam/list
import glint/flag
import file_streams/read_stream_error
import file_streams/read_text_stream.{type ReadTextStream}
import glint
import argv

const delimiter = "delimiter"

fn delimiter_flag() -> flag.FlagBuilder(String) {
  flag.string()
  |> flag.default("\t")
  |> flag.description("use DELIM instead of TAB for field delimiter")
}

type DELIM {
  Space(String)
  Comma(String)
  Pipe(String)
  Semicolon(String)
  Tab(String)
  Unsupported(String)
}

fn do_read_by_delimiter(
  acc: String,
  rts: ReadTextStream,
  delim: DELIM,
) -> String {
  case read_text_stream.read_line(rts) {
    Error(e) -> {
      case e {
        read_stream_error.EndOfStream -> acc
        _ -> {
          io.debug(e)
          io.println_error("error encountered while reading file")
          panic
        }
      }
    }
    Ok(v) -> {
      do_read_by_delimiter(acc <> v, rts, delim)
    }
  }
}

fn read_by_delimiter(rts: ReadTextStream, delim: DELIM) -> String {
  do_read_by_delimiter("", rts, delim)
}

fn run_cut(input: glint.CommandInput) -> Nil {
  // get flag 'delimiter' from cli argument
  let assert Ok(f) = flag.get_string(from: input.flags, for: delimiter)
  let delim = case f {
    " " -> Space(f)
    "," -> Comma(f)
    "|" -> Pipe(f)
    ";" -> Semicolon(f)
    "\t" -> Tab(f)
    _ -> Unsupported(f)
  }

  // get args filepath
  let file_path = case list.first(input.args) {
    Error(e) -> {
      io.debug(e)
      io.println_error("error extracting argument")
      panic
    }
    Ok(value) -> value
  }

  // read file from filepath given
  let assert Ok(rts) = read_text_stream.open(file_path)
  let content = read_by_delimiter(rts, delim)
  read_text_stream.close(rts)
  io.println(content)
}

pub fn main() {
  glint.new()
  |> glint.with_name("cut")
  |> glint.add(
    at: [],
    do: glint.command(run_cut)
      |> glint.flag(delimiter, delimiter_flag())
      |> glint.description(
        "Print selected parts of lines from each FILE to standard output.\n\nWith no FILE, or when FILE is -, read standard input.",
      ),
  )
  |> glint.run(argv.load().arguments)
}
