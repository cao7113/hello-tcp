defmodule HelloTcp.Server do
  use GenServer

  require Logger

  def start_link(port) do
    GenServer.start_link(__MODULE__, port, name: __MODULE__)
  end

  @impl true
  def init(port) do
    case :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true]) do
      {:ok, socket} ->
        Logger.info("Server listening on port #{port}")
        {:ok, socket, {:continue, :accept_connections}}

      {:error, reason} ->
        Logger.error("Failed to start server: #{reason}")
        {:stop, reason}
    end
  end

  @impl true
  def handle_continue(:accept_connections, socket) do
    case :gen_tcp.accept(socket) do
      {:ok, client} ->
        Logger.info("Client connected")

        Task.start_link(fn ->
          :gen_tcp.send(client, "Welcome to HelloTCP #{Application.spec(:hello_tcp, :vsn)}\n")
          reply_help(client)
          handle_client(client)
        end)

        {:noreply, socket, {:continue, :accept_connections}}

      {:error, reason} ->
        Logger.error("Failed to accept connection: #{reason}")
        {:stop, reason, socket}
    end
  end

  defp handle_client(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        Logger.info("handling request data: #{data |> inspect}")
        req = String.downcase(data)
        handle_request(socket, req)
        handle_client(socket)

      {:error, :closed} ->
        Logger.info("Client disconnected")
        :gen_tcp.close(socket)

      {:error, reason} ->
        Logger.error("Error receiving data: #{reason}")
        :gen_tcp.close(socket)
    end
  end

  defp handle_request(socket, h) when h in ["h\n", "help\n"] do
    reply_help(socket)
  end

  defp handle_request(socket, hi) when hi in ["hi\n", "hello\n"] do
    :gen_tcp.send(socket, "Hello, client!\n")
  end

  defp handle_request(socket, "ping\n") do
    :gen_tcp.send(socket, "Pong!\n")
  end

  defp handle_request(socket, "echo " <> payload) do
    :gen_tcp.send(socket, "Echo: #{payload}")
  end

  defp handle_request(socket, "time\n") do
    :gen_tcp.send(socket, "Server time: #{DateTime.utc_now()}\n")
  end

  defp handle_request(socket, e) when e in ["exit\n", "e\n", "q\n", "quit\n"] do
    :gen_tcp.send(socket, "Goodbye!\n")
    :gen_tcp.close(socket)
  end

  defp handle_request(socket, info) do
    :gen_tcp.send(
      socket,
      "Unknown command #{info |> String.trim()}, type help to get more\n"
    )

    reply_help(socket)

    Logger.warning("unknown client request: #{info}")
  end

  defp reply_help(socket) do
    :gen_tcp.send(socket, "Support commands: [help, hello, ping, time, quit, echo xxx]\n")
  end
end
