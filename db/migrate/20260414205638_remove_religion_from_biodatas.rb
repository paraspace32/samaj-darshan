class RemoveReligionFromBiodatas < ActiveRecord::Migration[8.1]
  def change
    remove_column :biodatas, :religion, :string
  end
end
