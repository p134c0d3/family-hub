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

ActiveRecord::Schema[8.1].define(version: 2026_01_19_225119) do
  create_table "access_requests", force: :cascade do |t|
    t.string "city", null: false
    t.datetime "created_at", null: false
    t.date "date_of_birth", null: false
    t.string "email", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.datetime "reviewed_at"
    t.integer "reviewed_by_id"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_access_requests_on_email"
    t.index ["reviewed_by_id"], name: "index_access_requests_on_reviewed_by_id"
    t.index ["status"], name: "index_access_requests_on_status"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "chat_memberships", force: :cascade do |t|
    t.integer "chat_id", null: false
    t.datetime "created_at", null: false
    t.datetime "last_read_at"
    t.boolean "notifications_enabled", default: true, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["chat_id", "user_id"], name: "index_chat_memberships_on_chat_id_and_user_id", unique: true
    t.index ["chat_id"], name: "index_chat_memberships_on_chat_id"
    t.index ["user_id"], name: "index_chat_memberships_on_user_id"
  end

  create_table "chats", force: :cascade do |t|
    t.string "chat_type", null: false
    t.datetime "created_at", null: false
    t.integer "created_by_id"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["chat_type"], name: "index_chats_on_chat_type"
    t.index ["created_by_id"], name: "index_chats_on_created_by_id"
  end

  create_table "message_reactions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "emoji", null: false
    t.integer "message_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["message_id", "user_id", "emoji"], name: "index_message_reactions_on_message_id_and_user_id_and_emoji", unique: true
    t.index ["message_id"], name: "index_message_reactions_on_message_id"
    t.index ["user_id"], name: "index_message_reactions_on_user_id"
  end

  create_table "message_read_receipts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "message_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["message_id", "user_id"], name: "index_message_read_receipts_on_message_id_and_user_id", unique: true
    t.index ["message_id"], name: "index_message_read_receipts_on_message_id"
    t.index ["user_id"], name: "index_message_read_receipts_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.integer "chat_id", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.boolean "edited", default: false, null: false
    t.text "encrypted_content", null: false
    t.string "encryption_iv"
    t.integer "parent_message_id"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["chat_id", "created_at"], name: "index_messages_on_chat_id_and_created_at"
    t.index ["chat_id"], name: "index_messages_on_chat_id"
    t.index ["deleted_at"], name: "index_messages_on_deleted_at"
    t.index ["parent_message_id"], name: "index_messages_on_parent_message_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "themes", force: :cascade do |t|
    t.json "colors", null: false
    t.datetime "created_at", null: false
    t.integer "created_by_id"
    t.boolean "is_default", default: false, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_themes_on_created_by_id"
    t.index ["is_default"], name: "index_themes_on_is_default"
    t.index ["name"], name: "index_themes_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "city", null: false
    t.string "color_mode", default: "system", null: false
    t.datetime "created_at", null: false
    t.date "date_of_birth", null: false
    t.string "email", null: false
    t.string "encryption_key_salt"
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.boolean "notify_email", default: true, null: false
    t.boolean "notify_in_app", default: true, null: false
    t.boolean "notify_push", default: false, null: false
    t.boolean "password_changed", default: false, null: false
    t.string "password_digest", null: false
    t.string "role", default: "member", null: false
    t.bigint "selected_theme_id"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["status"], name: "index_users_on_status"
  end

  add_foreign_key "access_requests", "users", column: "reviewed_by_id"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "chat_memberships", "chats"
  add_foreign_key "chat_memberships", "users"
  add_foreign_key "chats", "users", column: "created_by_id"
  add_foreign_key "message_reactions", "messages"
  add_foreign_key "message_reactions", "users"
  add_foreign_key "message_read_receipts", "messages"
  add_foreign_key "message_read_receipts", "users"
  add_foreign_key "messages", "chats"
  add_foreign_key "messages", "messages", column: "parent_message_id"
  add_foreign_key "messages", "users"
  add_foreign_key "themes", "users", column: "created_by_id"
  add_foreign_key "users", "themes", column: "selected_theme_id"
end
