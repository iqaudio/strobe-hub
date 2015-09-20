defmodule Otis do
  use Application

  @sample_freq 44100
  @sample_bits 16
  @sample_channels 2

  @stream_frame_bits  192
  @stream_frame_bytes 24

  # Final bitrate  is 176,400 Bytes/s
  # So 176400 = @stream_bytes_per_step * ( 1000 / @stream_interval_ms)
  # These numbers are chosen so that the gap between frames is some integer
  # number of milliseconds.

  # The higher the @multiplier the bigger each individual frame is, the longer
  # the gap between frames, the less work the server has to do and (probably)
  # the more reliable and the stream is *but* the longer the gap between
  # pressing stop and hearing the music stop
  @multiplier             2
  @stream_frames_per_step 147  * @multiplier
  @stream_bytes_per_step  3528 * @multiplier
  @stream_interval_ms     20   * @multiplier
  # Used a lot by the broadcasting system
  @stream_interval_us     1000 * @stream_interval_ms

  def sample_freq, do: @sample_freq
  def sample_bits, do: @sample_bits
  def sample_channels, do: @sample_channels

  def stream_interval_ms, do: @stream_interval_ms
  def stream_interval_us, do: @stream_interval_us
  def stream_bytes_per_step, do: @stream_bytes_per_step

  def start(_type, _args) do
    Otis.Supervisor.start_link
  end

  def init(_args) do
    IO.inspect [:starting, Otis, _args]
    :ok
  end

  def milliseconds do
    :erlang.monotonic_time(:milli_seconds)
  end

  def microseconds do
    :erlang.monotonic_time(:micro_seconds)
  end
end
