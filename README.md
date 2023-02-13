# DockerizePhx

This mix task is intended to help you get started with Docker and Phoenix. When run, it will create a `Dockerfile` and `docker-compose.yml` file for you. The docker-compose configuration will create a container for the app (referred to as `web`), and a container for the database (referred to as `db`). The Phoenix app's `dev.exs` file is then altered to use the database container as its database and tweaked to allow the web server to be bound to the `0.0.0.0` address so that it can be accessed from outside the container.

Once you have run the mix task, you can run the app with `docker-compose up` and access it at `http://localhost:4000`.

## Caveats

When writing versions to the Dockerfile, we match whatever the currently installed Elixir version is. For the Phoenix version, we use whatever the version is in the current `Application`, or fall back to just grabbing the latest version from hex.pm.

The alterations to the `dev.exs` file are fairly brittle regex replacements. If you have modified the structure of the config before running the mix task, it may not work as expected.

## Installation

* Create a new Phoenix project
* Then

  ```shell
  mix archive.install github tjl2/dockerize_phx
  mix dockerize_phx

  ```

* Create the DB, from inside the web container
  
  ```shell
  docker-compose run web mix ecto.create
  ```

* Run the app

  ```shell
  docker-compose up
  ```

From now on, whenever you need to run any `mix` commands, or `iex` sessions, you should do so from within the 'web' container:

```shell
docker compose exec web <your command>
```

I personally have an alias for just starting a shell in the container:

```shell
alias dcew='docker-compose exec web'
```
