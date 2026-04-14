class AddBiodataFields < ActiveRecord::Migration[8.1]
  def change
    add_column :biodatas, :father_name, :string
    add_column :biodatas, :mother_name, :string
    add_column :biodatas, :city_hi, :string
    add_column :biodatas, :job_location, :string
  end
end
