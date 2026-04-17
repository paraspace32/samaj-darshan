class AddBirthTimeHiToBiodatas < ActiveRecord::Migration[8.1]
  def change
    add_column :biodatas, :birth_time_hi, :string
  end
end
