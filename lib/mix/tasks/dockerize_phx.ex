defmodule Mix.Tasks.DockerizePhx do
  @moduledoc """
  Set up a Phoenix app for local development with Docker Compose.
  """
  alias DockerizePhx.MixProject

  @shortdoc "Configure Docker Compose setup for local Phoenix dev"

  use Mix.Task

  @impl Mix.Task
  def run(_) do
    DockerizePhx.write_dockerfile()
    DockerizePhx.write_docker_compose()
    DockerizePhx.create_db_data_volume()
  end
end
