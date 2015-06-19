class AddQueueToDelayedJobs < ActiveRecord::Migration
  def up
    add_column :delayed_jobs, :queue, :string
  end

  def down
    remove_column :delayed_jobs, :queue
  end
end
