defmodule DockerizePhx do
  @moduledoc """
  `DockerizePhx` library for use with the dockerize_phx mix task.
  https://github.com/tjl2/dockerize_phx
  """

  require EEx
  require Hex

  @config_files %{dev: "config/dev.exs", test: "config/test.exs"}
  @db_params_regex ~r/username:[[:blank:]]+".*",\n.*password:[[:blank:]]+".*",\n.*hostname:[[:blank:]]+".*",/
  @db_params ~S(username: "postgres",
  password: "postgres",
  hostname: "db",)

  def write_dockerfile(force) do
    if File.exists?("Dockerfile") && !force do
      IO.puts("Dockerfile already present. Use `mix dockerize_phx --force` to overwrite")
    else
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
  end

  def write_docker_compose(force) do
    if File.exists?("docker-compose.yaml") && !force do
      IO.puts("docker-compose.yaml already present. Use `mix dockerize_phx --force` to overwrite")
    else
      app_name = app_name_string()
      data_volume_name = app_name <> "-data"

      docker_compose_yaml =
        EEx.eval_file(Path.join(template_dir(), "docker-compose.yaml.eex"),
          app_name: app_name,
          data_volume: data_volume_name
        )

      File.write("docker-compose.yaml", docker_compose_yaml)
    end
  end

  def create_db_data_volume() do
    volume_name = app_name_string() <> "-data"

    if !docker_volume_exists?(volume_name) do
      {output, return_code} =
        System.cmd("docker", ~w[volume create --name #{volume_name} -d local])

      if return_code != 0 do
        IO.puts("Docker volume creation failed: #{output}")
      end
    end
  end

  def modify_http_listen_ip do
    if File.exists?(@config_files[:dev]) do
      {:ok, config} = File.read(@config_files[:dev])

      new_config =
        Regex.replace(~r/http\: \[ip\: \{.*, .*, .*, .*\}/, config, "http: [ip: {0, 0, 0, 0}")

      File.write(@config_files[:dev], new_config)
    end
  end

  def modify_db_configs do
    Enum.each(@config_files, fn {_env, config_file} ->
      if File.exists?(config_file) do
        {:ok, config} = File.read(config_file)

        new_config = Regex.replace(@db_params_regex, config, @db_params)

        File.write(config_file, new_config)
      end
    end)
  end

  # We try and get whatever Phoenix version exists in the app directory, then
  # fall back to just grabbing the latest stable from Hex
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

  # Returns nil if we can't find a Phoenix dependency in this app
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
    if File.exists?("priv/templates/Dockerfile.eex") do
      local_template_dir()
    else
      archive_template_dir()
    end
  end

  # Needed when developing and not using the installed archive
  defp local_template_dir, do: Path.join(["priv", "templates"])

  defp archive_template_dir do
    [dockerize_phx_latest | _tail] =
      Mix.path_for(:archives) |> Path.join("dockerize_phx*") |> Path.wildcard() |> Enum.sort()

    Path.join([dockerize_phx_latest, Path.basename(dockerize_phx_latest), "priv", "templates"])
  end
end
