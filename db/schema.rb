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

ActiveRecord::Schema[7.1].define(version: 2025_05_08_150902) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "customers", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "phone"
    t.string "address"
    t.string "city"
    t.string "province"
    t.string "postal_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "memberships", force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "customer_id", null: false
    t.string "membership_type"
    t.string "status"
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_memberships_on_customer_id"
    t.index ["order_id"], name: "index_memberships_on_order_id"
  end

  create_table "memorials", force: :cascade do |t|
    t.integer "user_id", null: false
    t.date "dob"
    t.date "dod"
    t.string "first_name", limit: 100
    t.string "last_name", limit: 100
    t.integer "religion"
    t.text "bio"
    t.string "caption", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_private", default: false
    t.string "pin_code"
    t.index ["user_id"], name: "index_memorials_on_user_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "uuid"
    t.integer "customer_id"
    t.string "membership_type"
    t.decimal "amount"
    t.string "status"
    t.string "payment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uuid"], name: "index_orders_on_uuid", unique: true
  end

  create_table "promotional_campaigns", force: :cascade do |t|
    t.string "name", null: false
    t.string "utm_campaign", null: false
    t.string "utm_source", default: "qr_promocional", null: false
    t.string "utm_medium", default: "offline", null: false
    t.boolean "active", default: true, null: false
    t.integer "qr_count"
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["utm_campaign"], name: "index_promotional_campaigns_on_utm_campaign", unique: true
  end

  create_table "qr_codes", force: :cascade do |t|
    t.string "code", null: false
    t.string "membership_type", null: false
    t.datetime "used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "memorial_id"
    t.string "state", default: "available"
    t.integer "order_id"
    t.integer "intermediary_id"
    t.integer "sold_to_id"
    t.index ["code"], name: "index_qr_codes_on_code", unique: true
    t.index ["intermediary_id"], name: "index_qr_codes_on_intermediary_id"
    t.index ["memorial_id"], name: "index_qr_codes_on_memorial_id"
    t.index ["order_id"], name: "index_qr_codes_on_order_id"
    t.index ["sold_to_id"], name: "index_qr_codes_on_sold_to_id"
  end

  create_table "shipping_infos", force: :cascade do |t|
    t.integer "order_id", null: false
    t.string "tracking_code"
    t.string "carrier_name"
    t.string "status", default: "pending"
    t.date "shipped_date"
    t.date "estimated_delivery_date"
    t.text "notes"
    t.string "invoice_filename"
    t.boolean "invoice_sent", default: false
    t.boolean "tracking_notification_sent", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "invoice_number"
    t.date "invoice_date"
    t.index ["order_id"], name: "index_shipping_infos_on_order_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "terms_of_service", default: false, null: false
    t.boolean "admin", default: false, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "memberships", "customers"
  add_foreign_key "memberships", "customers"
  add_foreign_key "memberships", "orders"
  add_foreign_key "memberships", "orders"
  add_foreign_key "memorials", "users"
  add_foreign_key "qr_codes", "memorials"
  add_foreign_key "qr_codes", "orders"
  add_foreign_key "qr_codes", "users", column: "intermediary_id"
  add_foreign_key "qr_codes", "users", column: "sold_to_id"
  add_foreign_key "shipping_infos", "orders"
end
