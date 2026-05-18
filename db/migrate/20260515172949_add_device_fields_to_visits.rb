class AddDeviceFieldsToVisits < ActiveRecord::Migration[8.1]
  def change
    add_column :visits, :device_type, :string
    add_column :visits, :browser, :string
    add_column :visits, :os, :string
    add_column :visits, :new_visitor, :boolean, default: true
    add_column :visits, :duration_seconds, :integer
  end
end
