class RemoveForeignKeyFromPiiRecords < ActiveRecord::Migration[8.1]
  def change
    # Remove foreign key constraint - user_id is reserved for future use
    # when integrating with authentication system
    remove_foreign_key :pii_records, :users

    # Make user_id nullable since it's not currently enforced
    change_column_null :pii_records, :user_id, true
  end
end
