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

fn do_get_element(seq: List(String), index: Int, cur: Int) -> String {
  case seq {
    [] -> ""
    [first, ..rest] -> {
      case cur {
        cur if cur == index -> first
        _ -> do_get_element(rest, index, cur + 1)
      }
    }
  }
}

fn get_element(for seq: List(String), at position: Int) -> String {
  do_get_element(seq, position - 1, 0)
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
          io.debug(e)
          io.println_error("error encountered while reading file")
          shellout.exit(1)
          ""
        }
      }
    }
    Ok(v) -> {
      let cell_val = string.split(v, on: get_delim_value(delim))
          |> get_element(at: field) <> "\n"
      do_read_by_delimiter(acc <> cell_val, rts, delim, field)
    }
  }
}

fn read_by_delimiter(rts: ReadTextStream, delim: DELIM, field: Int) -> String {
  do_read_by_delimiter("", rts, delim, field)
}

fn run_cut(input: glint.CommandInput) -> Nil {
  // get flag 'delimiter' from cli argument
  let assert Ok(d) = flag.get_string(from: input.flags, for: delimiter)
  let delim = map_input_to_delim(d)

  let assert Ok(f) = flag.get_int(from: input.flags, for: field)
  let field = case f {
    f if f > 0 -> f
    f if f <= 0 -> {
      io.println_error("cut: field is numbered from 1")
      shellout.exit(1)
      0
    }
    _ -> {
      io.println_error("cut: invalid field value")
      shellout.exit(1)
      0
    }
  }

  // get args filepath
  let file_path = case list.first(input.args) {
    Error(e) -> {
      io.debug(e)
      io.println_error("error extracting argument")
      shellout.exit(1)
      ""
    }
    Ok(value) -> value
  }

  // read file from filepath given
  let assert Ok(rts) = read_text_stream.open(file_path)
  let content = read_by_delimiter(rts, delim, field)
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
      |> glint.flag(field, field_flag())
      |> glint.description(
        "Print selected parts of lines from each FILE to standard output.\n",
      ),
  )
  |> glint.run(argv.load().arguments)
}
