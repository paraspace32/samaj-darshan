class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :phone, null: false
      t.string :email
      t.string :password_digest, null: false
      t.integer :role, default: 0, null: false
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :users, :phone, unique: true
    add_index :users, :email, unique: true
    add_index :users, :role
  end
end
