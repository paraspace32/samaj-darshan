class AddBirthTimeToBiodatas < ActiveRecord::Migration[8.1]
  def change
    add_column :biodatas, :birth_time, :string
  end
end
