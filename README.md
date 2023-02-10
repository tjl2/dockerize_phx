# DockerizePhx

**TODO: Add description**

## Installation

* Create a new Phoenix project
* Then
  ```
  mix archive.install github tjl2/dockerize_phx
  mix dockerize_phx
  ```
* Create the DB
  ```
  docker-compose run web mix ecto.create
  ```
* Run the app
  ```
  docker-compose up
  ```

From now on, whenever you need to run any `mix` commands, or `iex` sessions, you can do so from within the container:

```
docker compose exec web <your command>
```

I personally have an alias for just starting a shell in the container:

```
alias dcew='docker-compose exec web'
```
