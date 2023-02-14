defmodule Mix.Tasks.DockerizePhx do
  @moduledoc """
  Set up a Phoenix app for local development with Docker Compose.
  """

  @shortdoc "Configure Docker Compose setup for local Phoenix dev"

  use Mix.Task

  @impl Mix.Task
  def run(opts) do
    force = Enum.any?(opts, &(&1 == "--force"))
    DockerizePhx.write_dockerfile(force)
    DockerizePhx.write_docker_compose(force)
    DockerizePhx.create_db_data_volume()
    DockerizePhx.modify_http_listen_ip()
    DockerizePhx.modify_db_configs()
  end
end
