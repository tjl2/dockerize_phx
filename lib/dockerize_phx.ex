defmodule DockerizePhx do
  @moduledoc """
  Documentation for `DockerizePhx`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> DockerizePhx.hello()
      :world

  """
  require EEx
  require Hex

  def write_dockerfile() do
    app_name = app_name_string()
    ex_version = System.version()
    phx_version = phoenix_version()

    dockerfile_content =
      EEx.eval_file(Path.join(template_dir(), "Dockerfile.eex"),
        app_name: app_name,
        ex_version: ex_version,
        phx_version: phx_version
      )

    File.write("Dockerfile", dockerfile_content)
  end

  def write_docker_compose() do
    app_name = app_name_string()
    data_volume_name = app_name <> "-data"

    docker_compose_yaml =
      EEx.eval_file(Path.join(template_dir(), "docker-compose.yaml.eex"),
        app_name: app_name,
        data_volume: data_volume_name
      )

    File.write("docker-compose.yaml", docker_compose_yaml)
  end

  def create_db_data_volume() do
    if !docker_volume_exists?(app_name_string()) do
      {output, return_code} =
        System.cmd("docker", ~w[volume create --name #{app_name_string()} -d local])

      if return_code != 0 do
        IO.puts("Docker volume creation failed: #{output}")
      end
    end
  end

  defp phoenix_version do
    cond do
      !!local_phx_version() -> local_phx_version()
      true -> hex_phoenix_version()
    end
  end

  defp hex_phoenix_version do
    Hex.start()

    case Hex.API.Package.get(:hexpm, "phoenix") do
      {:ok, {200, response, _headers}} ->
        response
        |> Map.get("latest_stable_version")

      {:ok, {404, _, _}} ->
        "NO VERSION FOUND - FILL ME IN"

      {:error, _reason} ->
        "NO VERSION FOUND - FILL ME IN"
    end
  end

  defp local_phx_version do
    !!Application.spec(:phoenix, :vsn)
  end

  defp app_name_string() do
    Mix.Project.config()[:app] |> Atom.to_string()
  end

  defp docker_volume_exists?(volume_name) do
    {_output, return_code} =
      System.cmd("docker", ~w[volume inspect #{volume_name}], stderr_to_stdout: true)

    return_code == 0
  end

  defp template_dir do
    [dockerize_phx_latest | _tail] =
      Mix.path_for(:archives) |> Path.join("dockerize_phx*") |> Path.wildcard() |> Enum.sort()

    Path.join([dockerize_phx_latest, Path.basename(dockerize_phx_latest), "priv", "templates"])
  end
end
