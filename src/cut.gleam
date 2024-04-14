import gleam/io
import gleam/list
import gleam/string
import gleam/option.{None, Some}
import argv
import glint
import cffi
import cerror
import cflag
import glint/flag
import creader.{type DELIM}
import file_streams/read_text_stream

fn extract_args(input: glint.CommandInput) -> #(DELIM, Int, String) {
  let assert Ok(d) = flag.get_string(from: input.flags, for: cflag.delimiter)
  let delim = creader.map_input_to_delim(d)

  let assert Ok(f) = flag.get_int(from: input.flags, for: cflag.field)
  let field = case f {
    f if f > 0 -> f
    f if f <= 0 -> {
      cerror.println_error_extend(
        title: "field is numbered from 1",
        reason: None,
      )
      cffi.shutdown(1)
    }
    _ -> {
      cerror.println_error_extend(title: "invalid field value", reason: None)
      cffi.shutdown(1)
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
      cerror.println_error_extend(
        title: "fail to open file '" <> file_path <> "'",
        reason: Some(e),
      )
      cffi.shutdown(1)
    }
    Ok(v) -> v
  }

  let result = creader.read_by_delimiter(rts, delim, field)

  case read_text_stream.close(rts) {
    Error(e) -> {
      cerror.println_error_extend(
        title: "extracting 'filepath' argument",
        reason: Some(e),
      )
      cffi.shutdown(1)
    }
    _ -> Nil
  }

  result
}

fn from_stdin(delim: creader.DELIM, field: Int) -> String {
  creader.read_by_delimiter_stdin(delim, field)
}

pub type Config {
  Config(delimiter: DELIM, field: Int, file_path: String)
}

pub fn result_stdin_or_path(cfg: Config) -> String {
  case string.length(cfg.file_path) {
    0 -> from_stdin(cfg.delimiter, cfg.field)
    _ -> from_path(cfg.delimiter, cfg.field, cfg.file_path)
  }
}

fn run(input: glint.CommandInput) -> Nil {
  let #(delim, field, file_path) = extract_args(input)
  result_stdin_or_path(Config(
    delimiter: delim,
    field: field,
    file_path: file_path,
  ))
  |> io.println
}

pub fn main() {
  glint.new()
  |> glint.with_name("cut")
  |> glint.add(
    at: [],
    do: glint.command(run)
      |> glint.flag(cflag.delimiter, cflag.delimiter_flag())
      |> glint.flag(cflag.field, cflag.field_flag())
      |> glint.description(
        "Print selected parts of lines from each FILE to standard output.\n",
      ),
  )
  |> glint.run(argv.load().arguments)
}
