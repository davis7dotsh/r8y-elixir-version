defmodule R8yV4.Workers.ChannelSync do
  use Oban.Worker, queue: :default, max_attempts: 3

  require Logger

  alias R8yV4.Sync.ChannelSync

  @impl Oban.Worker
  def perform(%Oban.Job{} = job) do
    Logger.info("channel sync job triggered", job_id: job.id)
    :ok = ChannelSync.sync_all_channels()
    :ok
  end
end
