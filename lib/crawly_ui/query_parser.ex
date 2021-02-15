defmodule CrawlyUI.QueryParser do
  @moduledoc """
  Implementing efficient parser combinators.
  """

  import NimbleParsec

  key = ascii_string([?a..?z, ?A..?Z, ?\s, ?\t], min: 1)
  value = ascii_string([?a..?z, ?A..?Z, ?0..?9, ?\s, ?\t, ?%], min: 1)

  or_ = string("||")
  and_ = string("&&")

  defcombinatorp(:expr, key |> ignore(string(":")) |> concat(value))
  defcombinatorp(:operator, choice([or_, and_]))

  defcombinatorp(:term, concat(parsec(:expr), optional(parsec(:operator))))

  defparsec(:query, repeat(parsec(:term)))
end
