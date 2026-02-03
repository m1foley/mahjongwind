defmodule Mjw.Repo do
  use Ecto.Repo,
    otp_app: :mjw,
    adapter: Ecto.Adapters.Postgres
end
