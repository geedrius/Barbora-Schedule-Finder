defmodule Barbora.Telegram.UserGenServer do
  use GenServer
  require Logger

  @scan_interval 60 * 1000

  def start_link({chat_id, auth}),
    do: GenServer.start_link(__MODULE__, {chat_id, auth}, name: via_tuple(chat_id))

  defp via_tuple(chat_id), do: {:via, Registry, {:telegram_users, chat_id}}

  def init({chat_id, auth}) do
    Logger.debug("Initiating #{chat_id} user scanner")

    case Barbora.Client.client(auth) do
      %Tesla.Client{} = client ->
        {:ok, %{chat_id: chat_id, auth: auth, client: client}, @scan_interval}

      {:error, _} ->
        {:stop, :normal}
    end
  end

  @spec reserve(integer(), String.t(), {String.t(), String.t()}) :: :ok
  def reserve(chat_id, callback_id, reservation),
    do: GenServer.cast(via_tuple(chat_id), {:reserve, callback_id, reservation})

  @spec scan(integer()) :: :ok
  def scan(chat_id), do: GenServer.cast(via_tuple(chat_id), {:scan})

  def handle_info(:timeout, state) do
    scan(state.chat_id)
    {:noreply, state}
  end

  def handle_cast({:reserve, callback_id, reservation}, state) do
    timeout =
      case Barbora.Client.reserve_delivery(state.client, reservation) do
        :ok ->
          Barbora.Telegram.User.answer_callback(callback_id, "Reservation successful!")
          45 * 60 * 1000

        {:err, :already_taken} ->
          Barbora.Telegram.User.answer_callback(callback_id, "Sorry, this time is already taken")
          @scan_interval

        {:err, err} ->
          Logger.error("Error while reserving: #{inspect(err)}")

          Barbora.Telegram.User.answer_callback(
            callback_id,
            "Something went wrong with your reservation"
          )

          @scan_interval
      end

    {:noreply, state, timeout}
  end

  def handle_cast({:scan}, state) do
    Logger.debug("Scanning for deliveries for chat: #{state.chat_id}")

    # jei nera ryšio klaidų, tikrinam vietas kas 5 minutes arba kaip nurodyta
    days_from_today =
      case System.get_env("FILTER_MAX_DAYS") do
        nil -> 3
        value -> String.to_integer(value)
      end

    # domina tik šios dienos ir kitos dienos pristatymai
    dt_from = DateTime.utc_now |> DateTime.to_date
    dt_range = Date.range(dt_from, dt_from |> Date.add(days_from_today))
    fast_days = Enum.map(dt_range, fn x -> Date.to_iso8601(x) end)

    response = state.client
    |> Barbora.Client.get_deliveries()
    |> Barbora.Deliveries.filter_fast_deliveries(fast_days)
    |> Barbora.Telegram.User.notify_timeslots(state.chat_id)

    # jei nera ryšio klaidų, tikrinam vietas kas 5 minutes arba kaip nurodyta
    poll_in_minutes =
      case System.get_env("SCAN_INVERVAL_MINUTES") do
        nil -> 5
        value -> String.to_integer(value)
      end

    timeout = case response do
      {:ok, _} -> poll_in_minutes * @scan_interval
      _ -> @scan_interval
    end

    {:noreply, state, timeout}
  end
end
