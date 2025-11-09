class CreatePiiRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :pii_records do |t|
      t.string :first_name, null: false, limit: 50
      t.string :middle_name, limit: 50
      t.boolean :middle_name_override, default: false
      t.string :last_name, null: false, limit: 50
      t.text :ssn_encrypted, null: false
      t.string :ssn_last_four, limit: 4
      t.date :date_of_birth
      t.string :email
      t.string :phone
      t.string :street_address_1, null: false
      t.string :street_address_2

      t.string :city, null: false
      t.string :state, null: false, limit: 2
      t.string :zip_code, null: false, limit: 10
      t.references :user, null: false, foreign_key: true
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :pii_records, :ssn_encrypted, unique:true
    add_index :pii_records, :deleted_at
  end
end
