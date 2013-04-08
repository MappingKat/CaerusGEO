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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130217041153) do

  create_table "answers", :force => true do |t|
    t.string   "text"
    t.integer  "spresult_id"
    t.integer  "question_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.datetime "stamp"
    t.float    "number"
  end

  add_index "answers", ["question_id"], :name => "index_answers_on_question_id"
  add_index "answers", ["spresult_id"], :name => "index_answers_on_spresult_id"

  create_table "areas", :force => true do |t|
    t.string   "city"
    t.string   "country"
    t.string   "thumbnail"
    t.integer  "survey_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "areas", ["survey_id"], :name => "index_areas_on_survey_id"

  create_table "collaborators", :force => true do |t|
    t.string   "email"
    t.integer  "survey_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "collaborators", ["survey_id"], :name => "index_collaborators_on_survey_id"

  create_table "grids", :force => true do |t|
    t.string   "name"
    t.integer  "index"
    t.integer  "area_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "grids", ["area_id"], :name => "index_grids_on_area_id"

  create_table "points", :force => true do |t|
    t.float    "lat"
    t.float    "lng"
    t.integer  "location_id"
    t.string   "location_type"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.string   "location_subtype"
  end

  add_index "points", ["location_id", "location_type"], :name => "index_points_on_location_id_and_location_type"

  create_table "questions", :force => true do |t|
    t.integer  "index"
    t.string   "label"
    t.string   "form"
    t.string   "note"
    t.integer  "survey_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "questions", ["survey_id"], :name => "index_questions_on_survey_id"

  create_table "reports", :force => true do |t|
    t.string   "title"
    t.boolean  "status",                  :default => false
    t.integer  "survey_id"
    t.integer  "user_id"
    t.datetime "created_at",                                 :null => false
    t.datetime "updated_at",                                 :null => false
    t.string   "method",     :limit => 1
  end

  add_index "reports", ["survey_id"], :name => "index_reports_on_survey_id"
  add_index "reports", ["user_id"], :name => "index_reports_on_user_id"

  create_table "spresults", :force => true do |t|
    t.integer  "report_id"
    t.string   "uid"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.boolean  "status"
  end

  add_index "spresults", ["report_id"], :name => "index_spresults_on_report_id"

  create_table "surveys", :force => true do |t|
    t.string   "title"
    t.string   "description"
    t.boolean  "status",      :default => false
    t.integer  "user_id"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.boolean  "public",      :default => false
    t.string   "time_zone"
    t.string   "atlas_url"
    t.string   "wallmap_url"
    t.integer  "base"
  end

  add_index "surveys", ["user_id"], :name => "index_surveys_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "name"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.string   "time_zone"
  end

  add_index "users", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
