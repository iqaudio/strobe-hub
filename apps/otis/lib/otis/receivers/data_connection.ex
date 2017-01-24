defmodule Otis.Receivers.DataConnection do
  use Otis.Receivers.Protocol, type: :data

  def handle_cast({:data, data}, state) do
    case send_data(data, state) do
      :ok ->
        {:noreply, state}
      {:error, _reason} ->
        close_and_disconnect(state, :offline)
        {:stop, :normal, state}
    end
  end

  defp initial_settings, do: %{}
  defp monitor_connection(state), do: state
  defp receiver_alive(state), do: state
end
