import gleam/io
import gleam/list
import gleam/string
import gleam/option.{type Option, None, Some}
import glint/flag
import file_streams/read_stream_error
import file_streams/read_text_stream.{type ReadTextStream}
import glint
import argv

@external(erlang, "erlang", "halt")
fn shutdown(status: Int) -> a

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

fn exit_program_with_error(title msg: String, reason e: Option(a)) -> Nil {
  io.println_error("Error: " <> msg)
  case e {
    Some(a) -> {
      io.println_error("Detail: ")
      io.debug(a)
      Nil
    }
    None -> Nil
  }
    shutdown(1)
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
          exit_program_with_error(
            title: "error while while reading file",
            reason: Some(e),
          )
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
  |> string.trim_right
}

fn run_cut(input: glint.CommandInput) -> Nil {
  let assert Ok(d) = flag.get_string(from: input.flags, for: delimiter)
  let delim = map_input_to_delim(d)

  let assert Ok(f) = flag.get_int(from: input.flags, for: field)
  let field = case f {
    f if f > 0 -> f
    f if f <= 0 -> {
      exit_program_with_error(title: "field is numbered from 1", reason: None)
      0
    }
    _ -> {
      exit_program_with_error(title: "invalid field value", reason: None)
      0
    }
  }

  let file_path = case list.first(input.args) {
    Error(e) -> {
      exit_program_with_error(
        title: "extracting 'filepath' argument",
        reason: Some(e),
      )
      ""
    }
    Ok(value) -> value
  }

  let rts = case read_text_stream.open(file_path) {
    Error(e) -> {
      exit_program_with_error(
        title: "opening file '" <> file_path <> "'",
        reason: Some(e),
      )
      panic
    }
    Ok(v) -> v
  }

  read_by_delimiter(rts, delim, field)
  |> io.println

  case read_text_stream.close(rts) {
    Error(e) -> {
      exit_program_with_error(
        title: "extracting 'filepath' argument",
        reason: Some(e),
      )
      Nil
    }
    _ -> Nil
  }
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