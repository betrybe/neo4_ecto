defmodule Support.FileHelpers do
  def tmp_path do
    Path.expand("../tmp", __DIR__)
  end

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
