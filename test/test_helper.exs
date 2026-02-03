# Ensure all applications are started
{:ok, _} = Application.ensure_all_started(:mjw)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Mjw.Repo, :manual)
