defmodule Support.FileHelpers do
  @moduledoc false
  def tmp_path do
    Path.expand("../tmp", __DIR__)
  end

  # ToDo to really get advantage of this macro
  # path should come from config and not to be
  # hardcoded. So a further change could be
  # related to this path
  defmacro in_tmp(fun) do
    path = Path.absname("./priv/repo/migrations")

    quote do
      path = unquote(path)
      File.rm_rf!(path)
      File.mkdir_p!(path)
      File.cd!(path, fn -> unquote(fun).(path) end)
    end
  end
end
