defmodule HelloTcp.Client do
  require Logger

  def start(opts \\ []) do
    host = opts[:host] || "localhost"
    port = (opts[:port] || "4000") |> String.to_integer()

    case :gen_tcp.connect(String.to_charlist(host), port, [:binary, packet: :line, active: false]) do
      {:ok, socket} ->
        Logger.info("Connected to #{host}:#{port}")
        loop(socket)

      {:error, reason} ->
        Logger.error("Failed to connect to server: #{reason}")
    end
  end

  defp loop(socket) do
    message = IO.gets(">>client:> ") |> String.trim()

    if message in ~w[q quit e exit] do
      :gen_tcp.send(socket, "#{message}\n")
      Logger.info("Connection closed")
    else
      case :gen_tcp.send(socket, "#{message}\n") do
        :ok ->
          receive_response(socket)
          loop(socket)

        {:error, reason} ->
          Logger.warning("bad reason: #{reason}")
      end
    end
  end

  defp receive_response(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, "Goodbye!\n"} ->
        Logger.info("REPLY: server Goodbye!\n")
        :gen_tcp.close(socket)

      {:ok, response} ->
        Logger.info("REPLY: #{response}")

      {:error, :closed} ->
        Logger.info("Connection closed by server")

      {:error, reason} ->
        Logger.error("Error reason: #{reason}")
        :gen_tcp.close(socket)
    end
  end
end
