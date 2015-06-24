class AddLastRunReportToEtlConfigurations < ActiveRecord::Migration
  def change
    add_column :etl_configurations, :last_run_report, :text
  end
end
