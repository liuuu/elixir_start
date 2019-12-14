defmodule Metex.Worker do
  @name MW
  use GenServer

  def start_link(ops \\ []) do
    GenServer.start(__MODULE__, :ok, ops ++ [name: @name])
  end

  def init(:ok) do
    {:ok, %{}}
  end

  def stop do
    GenServer.cast(@name, :stop)
  end

  # client
  def get_temperature(location) do
    GenServer.call(@name, {:location, location})
  end

  def get_state do
    GenServer.call(@name, :get_state)
  end

  def reset_state do
    GenServer.cast(@name, :reset_state)
  end

  # server

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:location, location}, _from, state) do
    case temperature_of(location) do
      {:ok, temp} ->
        new_state = update_state(state, location)
        # _, return value, new_state
        {:reply, "#{temp}", new_state}

      _ ->
        {:reply, :error, state}
    end
  end

  def handle_cast(:reset_state, _state) do
    {:noreply, %{}}
  end

  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  defp update_state(old, location) do
    case Map.has_key?(old, location) do
      true ->
        # fn(val) -> val + 1 end
        Map.update!(old, location, &(&1 + 1))

      false ->
        Map.put_new(old, location, 1)
    end
  end

  def temperature_of(location) do
    url_for(location) |> HTTPoison.get() |> parse_response
  end

  defp url_for(location) do
    location = URI.encode(location)
    "http://api.openweathermap.org/data/2.5/weather?q=#{location}&appid=#{apikey()}"
  end

  defp parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body |> JSON.decode!() |> compute_temperature
  end

  defp compute_temperature(json) do
    try do
      temp = (json["main"]["temp"] - 273.15) |> Float.round(1)
      {:ok, temp}
    rescue
      _ -> :error
    end
  end

  defp apikey do
    "86571adc38f89f2bd66056ddd0f504a6"
  end
end
