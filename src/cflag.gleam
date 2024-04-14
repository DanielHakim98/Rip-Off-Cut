import glint/flag

pub const delimiter = "delimiter"

/// Init Flag for 'delimiter'
pub fn delimiter_flag() -> flag.FlagBuilder(String) {
  flag.string()
  |> flag.default("\t")
  |> flag.description("Use DELIM instead of TAB for field delimiter")
}

pub const field = "field"

/// Init Flag for 'field'
pub fn field_flag() -> flag.FlagBuilder(Int) {
  flag.int()
  |> flag.description("Select only this field. Valid value starts from 1")
}
