class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.string :external_id, null: false
      t.string :name
      t.string :email

      t.timestamps
    end

    add_index :users, :external_id, unique: true
  end
end
