import gleam/io
import gleam/option.{type Option, None, Some}

pub fn println_error_extend(title msg: String, reason e: Option(a)) -> Nil {
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
