defmodule Otis.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, [])
  end

  def init([packet_interval: packet_interval, packet_size: packet_size]) do
    emitter_pool_options = [
      name: {:local, Otis.EmitterPool},
      worker_module: Otis.Zone.Emitter,
      size: 16,
      max_overflow: 2
    ]

    children = [
      worker(Otis.DNSSD, []),
      worker(Otis.SNTP, []),
      worker(Otis.State, []),
      worker(Otis.State.Repo, []),
      worker(Otis.State.Events, []),
      worker(Otis.State.Persistence, []),
      worker(Otis.PortSequence, [5040, 10]),
      worker(Otis.ReceiverSocket, []),

      :poolboy.child_spec(Otis.EmitterPool, emitter_pool_options, [
        interval: packet_interval,
        packet_size: packet_size,
        pool: Otis.EmitterPool
      ]),

      supervisor(Otis.Broadcaster, []),
      supervisor(Otis.Zones.Supervisor, []),
      supervisor(Otis.Controllers, []),
      worker(Otis.Zones, []),
      worker(Otis.Startup, [Otis.State, Otis.Zones, Otis.Receivers], restart: :transient)
    ]
    supervise(children, strategy: :one_for_one)
  end
end
