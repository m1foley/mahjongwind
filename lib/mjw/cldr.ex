defmodule Mjw.Cldr do
  @moduledoc """
  CLDR backend for Mjw application
  """

  use Cldr,
    locales: ["en"],
    default_locale: "en",
    providers: [Cldr.Number],
    precompile_number_formats: ["#,##0"]
end
