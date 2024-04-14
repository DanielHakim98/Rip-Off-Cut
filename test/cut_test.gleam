import gleeunit
import creader
import cut
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`

// well actually this is more of integration test
// I'll need to refractor code to make it more testable
pub fn tab_input_from_filepath_test() {
  let cfg =
    cut.Config(
      delimiter: creader.map_input_to_delim("\t"),
      field: 1,
      file_path: "test/test.tsv",
    )
  cut.result_stdin_or_path(cfg)
  |> should.equal("f0\n0")
}

pub fn csv_input_from_filepath_test() {
  let cfg =
    cut.Config(
      delimiter: creader.map_input_to_delim(","),
      field: 2,
      file_path: "test/test.csv",
    )
  cut.result_stdin_or_path(cfg)
  |> should.equal("f1\n1")
}
