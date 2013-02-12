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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130212214801) do

  create_table "identifiers_to_be_assigned", :force => true do |t|
    t.string   "file"
    t.string   "assigned"
    t.datetime "pulled_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "legacy_national_ids", :force => true do |t|
    t.string   "value"
    t.string   "person_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "voided",      :default => 0
    t.string   "void_reason"
    t.datetime "voided_date"
  end

  create_table "master_syncs", :force => true do |t|
    t.string   "site_code",    :null => false
    t.date     "created_date"
    t.date     "updated_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "national_id_sites", :force => true do |t|
    t.string   "national_id", :null => false
    t.integer  "site_id",     :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "national_patient_identifiers", :force => true do |t|
    t.string   "value"
    t.integer  "decimal_num"
    t.string   "person_id"
    t.boolean  "pulled"
    t.datetime "assigned_at"
    t.integer  "assigner_id"
    t.integer  "assigner_site_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "voided",           :default => 0, :null => false
    t.string   "void_reason"
    t.datetime "voided_date"
  end

  add_index "national_patient_identifiers", ["decimal_num"], :name => "index_national_patient_identifiers_on_decimal_num", :unique => true

  create_table "pending_sync_requests", :force => true do |t|
    t.integer  "record_id"
    t.string   "record_type"
    t.string   "url"
    t.string   "http_method"
    t.string   "status_code"
    t.string   "method_name"
    t.string   "method_arguments"
    t.text     "request_body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "people", :force => true do |t|
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "version_number",        :default => "0"
    t.string   "creator_id"
    t.string   "creator_site_id"
    t.string   "remote_version_number"
    t.string   "given_name"
    t.string   "family_name"
    t.string   "gender"
    t.date     "birthdate"
    t.boolean  "birthdate_estimated",                    :null => false
  end

  create_table "person_name_codes", :force => true do |t|
    t.integer  "person_id",        :null => false
    t.string   "given_name_code",  :null => false
    t.string   "family_name_code", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "proxy_syncs", :force => true do |t|
    t.date     "start_date"
    t.date     "end_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sites", :force => true do |t|
    t.string   "name"
    t.string   "annotations"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "code",        :default => ""
  end

  create_table "syncs", :force => true do |t|
    t.string   "sync_site_id",   :null => false
    t.integer  "last_person_id", :null => false
    t.datetime "created_date",   :null => false
    t.datetime "updated_date",   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "password_hash"
    t.string   "email"
    t.string   "description"
    t.boolean  "disabled",      :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "site_id"
  end

end
