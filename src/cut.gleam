import gleam/io
import gleam/list
import gleam/string
import gleam/bit_array
import gleam/option.{type Option, None, Some}
import glint/flag
import file_streams/read_stream_error
import file_streams/read_text_stream.{type ReadTextStream}
import glint
import argv

@external(erlang, "erlang", "halt")
fn shutdown(status: Int) -> a

@external(erlang, "stdin_ffi", "io_get_line")
fn read_line() -> BitArray

fn println_error_extend(title msg: String, reason e: Option(a)) -> Nil {
  io.println_error("Error: " <> msg)
  case e {
    Some(a) -> {
      io.print_error("Detail: ")
      io.debug(a)
      Nil
    }
    None -> Nil
  }
}

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

pub type DELIM {
  Space(String)
  Comma(String)
  Pipe(String)
  Semicolon(String)
  Unsupported(String)
}

pub fn map_input_to_delim(input: String) -> DELIM {
  case input {
    " " -> Space(input)
    "," -> Comma(input)
    "|" -> Pipe(input)
    ";" -> Semicolon(input)
    _ -> Unsupported(input)
  }
}

fn get_delim_value(delim: DELIM) -> String {
  case delim {
    Space(v) -> v
    Comma(v) -> v
    Pipe(v) -> v
    Semicolon(v) -> v
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
          println_error_extend(
            title: "error while while reading file",
            reason: Some(e),
          )
          shutdown(1)
        }
      }
    }
    Ok(v) -> {
      let cell_val =
        string.split(v, on: get_delim_value(delim))
        |> get_element(at: field)
        |> string.trim_right
        <> "\n"
      do_read_by_delimiter(acc <> cell_val, rts, delim, field)
    }
  }
}

fn read_by_delimiter(rts: ReadTextStream, delim: DELIM, field: Int) -> String {
  do_read_by_delimiter("", rts, delim, field)
  |> string.trim_right
}

fn extract_args(input: glint.CommandInput) -> #(DELIM, Int, String) {
  let assert Ok(d) = flag.get_string(from: input.flags, for: delimiter)
  let delim = map_input_to_delim(d)

  let assert Ok(f) = flag.get_int(from: input.flags, for: field)
  let field = case f {
    f if f > 0 -> f
    f if f <= 0 -> {
      println_error_extend(title: "field is numbered from 1", reason: None)
      shutdown(1)
    }
    _ -> {
      println_error_extend(title: "invalid field value", reason: None)
      shutdown(1)
    }
  }

  let file_path = case list.first(input.args) {
    Error(_) -> ""
    Ok(value) -> value
  }

  #(delim, field, file_path)
}

fn from_path(delim: DELIM, field: Int, file_path: String) -> String {
  let rts = case read_text_stream.open(file_path) {
    Error(e) -> {
      println_error_extend(
        title: "fail to open file '" <> file_path <> "'",
        reason: Some(e),
      )
      shutdown(1)
    }
    Ok(v) -> v
  }

  let result = read_by_delimiter(rts, delim, field)

  case read_text_stream.close(rts) {
    Error(e) -> {
      println_error_extend(
        title: "extracting 'filepath' argument",
        reason: Some(e),
      )
      shutdown(1)
    }
    _ -> Nil
  }

  result
}

fn from_stdin(delim: DELIM, field: Int) -> String {
  read_by_delimiter_stdin(delim, field)
}

fn read_by_delimiter_stdin(delim: DELIM, field: Int) -> String {
  do_by_delimiter_stdin("", delim, field)
  |> string.trim_right
}

fn do_by_delimiter_stdin(acc: String, delim: DELIM, field: Int) -> String {
  case bit_array.to_string(read_line()) {
    Error(_) -> ""
    Ok(v) -> {
      case v {
        "" -> acc
        _ -> {
          let cell_val =
            string.split(v, on: get_delim_value(delim))
            |> get_element(at: field)
            |> string.trim_right
            <> "\n"

          do_by_delimiter_stdin(acc <> cell_val, delim, field)
        }
      }
    }
  }
}

pub type Config{
  Config(delimiter: DELIM, field: Int, file_path: String)
}

pub fn result_stdin_or_path(cfg: Config)->String{
    case string.length(cfg.file_path) {
    0 -> from_stdin(cfg.delimiter, cfg.field)
    _ -> from_path(cfg.delimiter, cfg.field, cfg.file_path)
  }
}

fn run_cut(input: glint.CommandInput) -> Nil {
  let #(delim, field, file_path) = extract_args(input)
  result_stdin_or_path(Config(delimiter:delim, field:field, file_path: file_path))
  |> io.println
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
