defmodule ZonesTest do
  use ExUnit.Case, async: true

  @moduletag :zones

  setup do
    {:ok, zones} = Otis.Zones.start_link(:test_zones)
    {:ok, zones: zones}
  end


  alias Otis.Zone

  test "allows for the adding of a zone", %{zones: zones} do
    {:ok, zone} = Zone.start_link(:zone_1, "Downstairs")
    Otis.Zones.add(zones, zone)
    {:ok, list } = Otis.Zones.list(zones)
    assert list == [zone]
  end

  test "lets you retrieve a zone by id", %{zones: zones} do
    {:ok, zone} = Zone.start_link(:zone_1, "Downstairs")
    Otis.Zones.add(zones, zone)
    {:ok, found } = Otis.Zones.find(zones, :zone_1)
    assert found == zone
  end

  test "returns :error if given an invalid id", %{zones: zones} do
    result = Otis.Zones.find(zones, "zone-2")
    assert result == :error
  end

  test "starts and adds the given zone", %{zones: zones} do
    {:ok, zone} = Otis.Zones.start_zone(zones, "1", "A Zone")
    {:ok, list} = Otis.Zones.list(zones)
    assert list == [zone]
  end
end

defmodule FakeMonitor do
  @moduledoc """
  Accepts all the messages that the real player status module does.
  """

  use GenServer
  defmodule S do
    # pretend to have these values
    defstruct time_diff: 22222222, delay: 1000 # both in us
  end

  def init( :ok ) do
    {:ok, %S{}}
  end

  def handle_call({:sync, {originate_ts} = packet}, _from, state) do
    {:reply, {originate_ts, fake_time(originate_ts, state)}, state}
  end

  def fake_time(originate_ts, %S{time_diff: time_diff, delay: delay} = _state) do
    originate_ts - (delay*0) + time_diff
  end
end

defmodule Otis.ZoneTest do
  use ExUnit.Case, async: true

  @moduletag :zone

  setup do
    name = "Downstairs"
    {:ok, monitor} = GenServer.start_link(FakeMonitor, :ok, name: Janis.Monitor)
    {:ok, zone} = Otis.Zone.start_link(:zone_1, name)
    {:ok, receiver} = Otis.Receiver.start_link(:receiver_1, node)
    {:ok, zone: zone, name: name, receiver: receiver}
  end

  test "gives its name", %{zone: zone, name: name} do
    {:ok, _name} = Otis.Zone.name(zone)
    assert _name == name
  end

  test "gives its id", %{zone: zone} do
    {:ok, id} = Otis.Zone.id(zone)
    assert id == :zone_1
  end

  test "starts with an empty receiver list", %{zone: zone} do
    {:ok, receivers} = Otis.Zone.receivers(zone)
    assert receivers == []
  end

  test "allows you to add a receiver", %{zone: zone, receiver: receiver} do
    :ok = Otis.Zone.add_receiver(zone, receiver)
    {:ok, receivers} = Otis.Zone.receivers(zone)
    assert receivers == [receiver]
  end

  test "ignores duplicate receivers", %{zone: zone, receiver: receiver} do
    :ok = Otis.Zone.add_receiver(zone, receiver)
    :ok = Otis.Zone.add_receiver(zone, receiver)
    {:ok, receivers} = Otis.Zone.receivers(zone)
    assert receivers == [receiver]
  end

  test "allows you to remove a receiver", %{zone: zone, receiver: receiver} do
    :ok = Otis.Zone.add_receiver(zone, receiver)
    :ok = Otis.Zone.remove_receiver(zone, receiver)
    {:ok, receivers} = Otis.Zone.receivers(zone)
    assert receivers == []
  end

  test "allows you to query the play pause state", %{zone: zone} do
    {:ok, state} = Otis.Zone.state(zone)
    assert state == :stop
  end

  test "allows you to toggle the play pause state", %{zone: zone} do

    {:ok, state} = Otis.Zone.play_pause(zone)
    assert state == :play
    {:ok, state} = Otis.Zone.play_pause(zone)
    assert state == :stop
  end
end
