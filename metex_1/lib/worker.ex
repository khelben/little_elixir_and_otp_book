defmodule Metex.Worker do

  @doc """
  first version of the Worker.

  call as follows in iex

    > cities = ["Singapore", "Monaco", "Vatican City", "Hong Kong", "Macau"]
    > cities |> Enum.map(fn city ->
        pid = spawn(Metex.Worker, :loop, [])
        send(pid, {self(), city})
      end)
    > flush() # => get the results
  """
  def loop do
    receive do
      {sender_pid, location} ->
        send(sender_pid, {:ok, temperature_of(location)})
      _ ->
        IO.puts "don't know how to process this message"
    end
    # no need to recursively call myself, as I will be spawned
    # only to lookup the temperature once.
    # loop()
  end

  def temperature_of(location) do
    result = url_for(location) |> HTTPoison.get |> parse_response
    case result do
      {:ok, temp} ->
        "#{location}: #{temp}°C"
      :error ->
        "#{location} not found"
    end
  end

  defp url_for(location) do
    location = URI.encode(location)
    "http://api.openweathermap.org/data/2.5/weather?q=#{location}&appid=#{apikey()}"
  end

  defp parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body |> JSON.decode! |> compute_temperature
  end

  defp parse_response(_) do
    :error
  end

  defp compute_temperature(json) do
    temp = (json["main"]["temp"] - 273.15) |> Float.round(1)
    {:ok, temp}
  end

  defp apikey do
    "c0af8c9a2c60764186d5bb6587f4502b"
  end
end
