class AddRegistrationUrlToWebinars < ActiveRecord::Migration[8.1]
  def change
    add_column :webinars, :registration_url, :string
  end
end
