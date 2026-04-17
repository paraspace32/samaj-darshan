class AddConsentFieldsToBiodatas < ActiveRecord::Migration[8.1]
  def change
    add_column :biodatas, :created_by_id, :bigint
    add_column :biodatas, :user_consented, :boolean, default: false, null: false
    add_column :biodatas, :consented_at, :datetime
    add_index  :biodatas, :created_by_id
  end
end
