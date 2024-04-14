/// It's just a call to erlang:halt
@external(erlang, "erlang", "halt")
pub fn shutdown(status: Int) -> a

/// Refer to stdin_ffi.erl
@external(erlang, "stdin_ffi", "io_get_line")
pub fn read_line() -> BitArray
