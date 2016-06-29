# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160629105720) do

  create_table "api_keys", force: :cascade do |t|
    t.integer  "user_id",      limit: 4
    t.string   "access_token", limit: 255
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "runs", force: :cascade do |t|
    t.integer  "user_id",       limit: 4
    t.integer  "task_id",       limit: 4
    t.string   "status",        limit: 32
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "code",          limit: 255
    t.string   "message",       limit: 2048
    t.text     "data",          limit: 65535
    t.text     "log",           limit: 16777215
    t.integer  "max_memory_kb", limit: 4
    t.integer  "max_time_ms",   limit: 4
  end

  create_table "tasks", force: :cascade do |t|
    t.string   "name",         limit: 255
    t.text     "description",  limit: 65535
    t.integer  "user_id",      limit: 4
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
    t.string   "checker",      limit: 255
    t.string   "task_type",    limit: 255,   default: "iofiles"
    t.text     "wrapper_code", limit: 65535
    t.string   "checker_lang", limit: 255
  end

  create_table "user_invites", force: :cascade do |t|
    t.string   "email",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255,  default: "", null: false
    t.string   "encrypted_password",     limit: 255,  default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,    default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.string   "file_path",              limit: 2048
    t.string   "confirmation_token",     limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
