import gleam/bit_array
import gleam/list
import gleam/string
import gleam/option.{Some}
import cffi
import cerror
import file_streams/read_stream_error
import file_streams/read_text_stream.{type ReadTextStream}

/// Delimiter type. Only support 'Space', 'Comma', 'Pipe', 'Semicolon'. 'Tab' as default
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

pub fn get_delim_value(delim: DELIM) -> String {
  case delim {
    Space(v) -> v
    Comma(v) -> v
    Pipe(v) -> v
    Semicolon(v) -> v
    Unsupported(v) -> v
  }
}

/// Reader from filepath provided
pub fn read_by_delimiter(
  rts: ReadTextStream,
  delim: DELIM,
  field: Int,
) -> String {
  do_read_by_delimiter("", rts, delim, field)
  |> string.trim_right
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
          cerror.println_error_extend(
            title: "error while while reading file",
            reason: Some(e),
          )
          cffi.shutdown(1)
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

/// Extract element from List(String) based on index. O(n) in term of time complexity
fn get_element(for seq: List(String), at position: Int) -> String {
  do_get_element(seq, position - 1)
}

fn do_get_element(seq: List(String), index: Int) -> String {
  case list.at(in: seq, get: index) {
    Error(_) -> ""
    Ok(v) -> v
  }
}

/// Reader for standard input by using custom Erlang FFI function
pub fn read_by_delimiter_stdin(delim: DELIM, field: Int) -> String {
  do_by_delimiter_stdin("", delim, field)
  |> string.trim_right
}

fn do_by_delimiter_stdin(acc: String, delim: DELIM, field: Int) -> String {
  case bit_array.to_string(cffi.read_line()) {
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
