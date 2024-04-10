import gleam/io
import gleam/list
import gleam/bit_array

import glint/flag
import file_streams/read_stream.{type ReadStream}
import file_streams/read_stream_error
import glint
import argv

const delimiter = "delimiter"

fn delimiter_flag() -> flag.FlagBuilder(String) {
  flag.string()
  |> flag.default("\t")
  |> flag.description("use DELIM instead of TAB for field delimiter")
}

type DELIM{
  Space(String)
  Comma(String)
  Pipe(String)
  Semicolon(String)
  Tab(String)
  Unsupported(String)
}


fn do_read_bytes_by_size(acc: BitArray, rs: ReadStream, buf_size: Int ) -> BitArray{
  case read_stream.read_bytes(rs, buf_size){
    Error(e) -> {
      case e {
        read_stream_error.EndOfStream -> acc
        _ -> {
          io.debug(e)
          io.println_error("error encountered while reading bytes")
          panic
        }
      }
    }
    Ok(v) -> {
      do_read_bytes_by_size(bit_array.append(acc, v),rs, buf_size)
    }
  }
}

fn read_bytes_by_size(rs: ReadStream, buf_size: Int)->BitArray{
  case buf_size {
    buf_size if buf_size <= 0 -> <<>>
    _ -> do_read_bytes_by_size(<<>>, rs, buf_size)
  }
}

fn run_cut(input: glint.CommandInput) -> Nil {
  // get flag 'delimiter' from cli argument
  let assert Ok(f) = flag.get_string(from: input.flags, for: delimiter)
  let _delim = case f {
    " " -> Space(f)
    "," -> Comma(f)
    "|" -> Pipe(f)
    ";" -> Semicolon(f)
    "\t" -> Tab(f)
    _ -> Unsupported(f)

  }
  // get args filepath
  let file_path = case list.first(input.args){
    Error(e) -> {
      io.debug(e)
      io.println_error("error extracting argument")
      panic
    }
    Ok(value) -> value
  }

  // read file from filepath given
  let assert Ok(reader) = read_stream.open(file_path)
  let bytes =  read_bytes_by_size(reader, 8)
  let assert Ok(content) = bit_array.to_string(bytes)
  io.println(content)
  Nil
}

pub fn main() {
  glint.new()
  |> glint.with_name("cut")
  |> glint.add(
    at: [],
    do: glint.command(run_cut)
      |> glint.flag(delimiter, delimiter_flag())
      |> glint.description(
        "Print selected parts of lines from each FILE to standard output.\n\nWith no FILE, or when FILE is -, read standard input."),
  )
  |> glint.run(argv.load().arguments)
}
