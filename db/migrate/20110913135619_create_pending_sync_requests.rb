class CreatePendingSyncRequests < ActiveRecord::Migration
  def self.up
    create_table :pending_sync_requests do |t|
      t.integer :record_id
      t.string :record_type
      t.string :url
      t.string :http_method
      t.string :status_code
      t.string :method_name
      t.string :method_arguments
      t.text :request_body

      t.timestamps
    end
  end

  def self.down
    drop_table :pending_sync_requests
  end
end
