defmodule GaPersonal.Workers.MediaCleanupWorker do
  @moduledoc """
  Oban cron worker that runs daily at 3 AM to permanently delete
  media files that were soft-deleted more than 30 days ago.
  Removes both GCS objects and database records.
  """
  use Oban.Worker, queue: :scheduled, max_attempts: 3

  require Logger

  alias GaPersonal.Media

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Logger.info("MediaCleanupWorker: Starting cleanup of expired media files")

    {:ok, count} = Media.hard_delete_expired()
    Logger.info("MediaCleanupWorker: Cleaned up #{count} expired media files")
    :ok
  end
end
