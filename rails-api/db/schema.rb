# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_11_09_234638) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "pii_records", force: :cascade do |t|
    t.string "city", null: false
    t.datetime "created_at", null: false
    t.date "date_of_birth"
    t.datetime "deleted_at"
    t.string "email"
    t.string "first_name", limit: 50, null: false
    t.string "last_name", limit: 50, null: false
    t.string "middle_name", limit: 50
    t.boolean "middle_name_override", default: false
    t.string "phone"
    t.text "ssn_encrypted", null: false
    t.string "ssn_last_four", limit: 4
    t.string "state", limit: 2, null: false
    t.string "street_address_1", null: false
    t.string "street_address_2"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "zip_code", limit: 10, null: false
    t.index ["deleted_at"], name: "index_pii_records_on_deleted_at"
    t.index ["ssn_encrypted"], name: "index_pii_records_on_ssn_encrypted", unique: true
    t.index ["user_id"], name: "index_pii_records_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "pii_records", "users"
end
