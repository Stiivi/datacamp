class AddIndexSessionIdToSessions < ActiveRecord::Migration
  def change
    add_index :sessions, :session_id
  end
end
