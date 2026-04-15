class AddPartnerFieldsToBiodatas < ActiveRecord::Migration[8.1]
  def change
    add_column :biodatas, :partner_age_min, :integer
    add_column :biodatas, :partner_age_max, :integer
    add_column :biodatas, :partner_education, :string
    add_column :biodatas, :partner_occupation, :string
    add_column :biodatas, :partner_expectations, :text
  end
end
