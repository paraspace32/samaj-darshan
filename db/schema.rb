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

ActiveRecord::Schema[8.1].define(version: 2026_04_03_054315) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  create_table "articles", force: :cascade do |t|
    t.integer "article_type", default: 0, null: false
    t.bigint "author_id", null: false
    t.bigint "category_id", null: false
    t.integer "comments_count", default: 0, null: false
    t.text "content_en", null: false
    t.text "content_hi", null: false
    t.datetime "created_at", null: false
    t.integer "likes_count", default: 0, null: false
    t.datetime "published_at"
    t.bigint "region_id", null: false
    t.string "rejection_reason"
    t.integer "status", default: 0, null: false
    t.string "title_en", null: false
    t.string "title_hi", null: false
    t.datetime "updated_at", null: false
    t.index ["article_type"], name: "index_articles_on_article_type"
    t.index ["author_id"], name: "index_articles_on_author_id"
    t.index ["category_id"], name: "index_articles_on_category_id"
    t.index ["published_at"], name: "index_articles_on_published_at"
    t.index ["region_id"], name: "index_articles_on_region_id"
    t.index ["status", "published_at"], name: "index_articles_on_status_and_published_at"
    t.index ["status"], name: "index_articles_on_status"
  end

  create_table "billboards", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.integer "billboard_type", default: 0, null: false
    t.integer "clicks_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.date "end_date"
    t.integer "impressions_count", default: 0, null: false
    t.string "link_url"
    t.integer "priority", default: 0, null: false
    t.date "start_date"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["active", "billboard_type", "priority"], name: "idx_billboards_active_type_priority"
    t.index ["active"], name: "index_billboards_on_active"
    t.index ["billboard_type"], name: "index_billboards_on_billboard_type"
  end

  create_table "categories", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "color", default: "#6366f1", null: false
    t.datetime "created_at", null: false
    t.string "name_en", null: false
    t.string "name_hi", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_categories_on_active"
    t.index ["position"], name: "index_categories_on_position"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["article_id"], name: "index_comments_on_article_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "likes", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["article_id", "user_id"], name: "index_likes_on_article_id_and_user_id", unique: true
    t.index ["article_id"], name: "index_likes_on_article_id"
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "regions", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name_en", null: false
    t.string "name_hi", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_regions_on_active"
    t.index ["position"], name: "index_regions_on_position"
    t.index ["slug"], name: "index_regions_on_slug", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name", null: false
    t.string "password_digest", null: false
    t.string "phone", null: false
    t.integer "role", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["phone"], name: "index_users_on_phone", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "articles", "categories"
  add_foreign_key "articles", "regions"
  add_foreign_key "articles", "users", column: "author_id"
  add_foreign_key "comments", "articles"
  add_foreign_key "comments", "users"
  add_foreign_key "likes", "articles"
  add_foreign_key "likes", "users"
end
