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

ActiveRecord::Schema[7.0].define(version: 2026_10_01_120000) do
  create_table "mailers", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "news_comments", force: :cascade do |t|
    t.text "message"
    t.integer "news_item_id"
    t.integer "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "news_items", force: :cascade do |t|
    t.text "message"
    t.integer "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "photo_album_comments", force: :cascade do |t|
    t.string "message", limit: 255
    t.integer "photo_album_id"
    t.integer "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "photo_album_pictures", force: :cascade do |t|
    t.integer "photo_album_id"
    t.string "filename", limit: 255
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "position"
  end

  create_table "photo_albums", force: :cascade do |t|
    t.string "title", limit: 255
    t.text "description"
    t.integer "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name", limit: 255
    t.string "last_name", limit: 255
    t.string "email", limit: 255
    t.string "password", limit: 255
    t.boolean "notify_news"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "isadmin"
    t.boolean "notify_photo_album"
  end

end
