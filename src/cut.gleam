import gleam/io
import gleam/list
import gleam/string
import glint/flag
import file_streams/read_stream_error
import file_streams/read_text_stream.{type ReadTextStream}
import glint
import argv
import shellout

const delimiter = "delimiter"

fn delimiter_flag() -> flag.FlagBuilder(String) {
  flag.string()
  |> flag.default("\t")
  |> flag.description("Use DELIM instead of TAB for field delimiter")
}

const field = "field"

fn field_flag() -> flag.FlagBuilder(Int) {
  flag.int()
  |> flag.description("Select only this field. Valid value starts from 1")
}

type DELIM {
  Space(String)
  Comma(String)
  Pipe(String)
  Semicolon(String)
  Tab(String)
  Unsupported(String)
}

fn map_input_to_delim(input: String) -> DELIM {
  case input {
    " " -> Space(input)
    "," -> Comma(input)
    "|" -> Pipe(input)
    ";" -> Semicolon(input)
    "\t" -> Tab(input)
    _ -> Unsupported(input)
  }
}

fn get_delim_value(delim: DELIM) -> String {
  case delim {
    Space(v) -> v
    Comma(v) -> v
    Pipe(v) -> v
    Semicolon(v) -> v
    Tab(v) -> v
    Unsupported(v) -> v
  }
}

fn do_get_element(seq: List(String), index: Int) -> String {
  case list.at(in: seq, get: index) {
    Error(_) -> ""
    Ok(v) -> v
  }
}

fn get_element(for seq: List(String), at position: Int) -> String {
  do_get_element(seq, position - 1)
}

fn do_read_by_delimiter(
  acc: String,
  rts: ReadTextStream,
  delim: DELIM,
  field: Int,
) -> String {
  case read_text_stream.read_line(rts) {
    Error(e) -> {
      case e {
        read_stream_error.EndOfStream -> acc
        _ -> {
          io.println_error("Error: error while while reading file")
          io.println_error("Detail: ")
          io.debug(e)
          shellout.exit(1)
          ""
        }
      }
    }
    Ok(v) -> {
      let cell_val =
        string.split(v, on: get_delim_value(delim))
        |> get_element(at: field)
        <> "\n"
      do_read_by_delimiter(acc <> cell_val, rts, delim, field)
    }
  }
}

fn read_by_delimiter(rts: ReadTextStream, delim: DELIM, field: Int) -> String {
  do_read_by_delimiter("", rts, delim, field)
}

fn run_cut(input: glint.CommandInput) -> Nil {
  let assert Ok(d) = flag.get_string(from: input.flags, for: delimiter)
  let delim = map_input_to_delim(d)

  let assert Ok(f) = flag.get_int(from: input.flags, for: field)
  let field = case f {
    f if f > 0 -> f
    f if f <= 0 -> {
      io.println_error("Error: field is numbered from 1")
      shellout.exit(1)
      0
    }
    _ -> {
      io.println_error("Error: invalid field value")
      shellout.exit(1)
      0
    }
  }

  let file_path = case list.first(input.args) {
    Error(e) -> {
      io.println_error("Error extracting 'filepath' argument")
      io.println_error("Detail: ")
      io.debug(e)
      shellout.exit(1)
      ""
    }
    Ok(value) -> value
  }

  let assert Ok(rts) = read_text_stream.open(file_path)
  read_by_delimiter(rts, delim, field)
  |> io.println
  read_text_stream.close(rts)
}

pub fn main() {
  glint.new()
  |> glint.with_name("cut")
  |> glint.add(
    at: [],
    do: glint.command(run_cut)
      |> glint.flag(delimiter, delimiter_flag())
      |> glint.flag(field, field_flag())
      |> glint.description(
        "Print selected parts of lines from each FILE to standard output.\n",
      ),
  )
  |> glint.run(argv.load().arguments)
}
