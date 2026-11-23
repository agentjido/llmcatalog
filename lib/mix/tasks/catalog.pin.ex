defmodule Mix.Tasks.Catalog.Pin do
  use Mix.Task

  @shortdoc "Stage the verified full catalog for the locked LLMDB release"

  @impl Mix.Task
  def run(args) do
    mode =
      case args do
        [] -> :existing_pin
        ["--update"] -> :new_pin
        _ -> Mix.raise("Use mix catalog.pin [--update]")
      end

    dir = "priv/llm_db"

    if mode == :new_pin or File.exists?(Path.join(dir, "catalog-manifest.json")) do
      Mix.Task.run("app.config")

      version =
        case Mix.Dep.Lock.read()[:llm_db] do
          {:hex, :llm_db, version, _, _, _, _, _} -> version
          _ -> Mix.raise("The catalog pin requires a locked Hex version of llm_db.")
        end

      case PetalBoilerplate.CatalogArtifact.stage(dir, version, mode) do
        :ok -> Mix.shell().info("Verified full catalog for LLMDB #{version}")
        {:error, reason} -> Mix.raise("Could not verify the full catalog: #{inspect(reason)}")
      end
    end
  end
end
