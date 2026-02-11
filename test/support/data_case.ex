defmodule Mjw.DataCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require database access.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Mjw.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Mjw.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Mjw.DataCase
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Mjw.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

    # Allow the BotService GenServer to access the sandbox
    if bot_service_pid = Process.whereis(MjwWeb.BotService) do
      Ecto.Adapters.SQL.Sandbox.allow(Mjw.Repo, self(), bot_service_pid)
    end

    # Allow the StaleGameSweeper GenServer to access the sandbox
    if game_sweeper_pid = Process.whereis(Mjw.Games.StaleGameSweeper) do
      Ecto.Adapters.SQL.Sandbox.allow(Mjw.Repo, self(), game_sweeper_pid)
    end

    :ok
  end
end
