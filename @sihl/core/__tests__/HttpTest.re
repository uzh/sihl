open Jest;
open Expect;

describe("Http", () => {
  test("parses header", () => {
    "Bearer foobar123"
    |> Sihl.App.Http.Core.parseAuthToken
    |> expect
    |> toEqual(Some("foobar123"))
  })
});
