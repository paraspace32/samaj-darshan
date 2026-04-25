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

ActiveRecord::Schema[8.1].define(version: 2026_04_25_082418) do
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

  create_table "biodatas", force: :cascade do |t|
    t.text "about_en"
    t.text "about_hi"
    t.string "annual_income"
    t.string "birth_time"
    t.string "birth_time_hi"
    t.string "caste"
    t.string "city", null: false
    t.string "city_hi"
    t.string "complexion"
    t.datetime "consented_at"
    t.string "contact_email"
    t.string "contact_phone"
    t.string "country", default: "India"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.date "date_of_birth", null: false
    t.string "education", null: false
    t.string "father_name"
    t.string "father_occupation"
    t.string "full_name", null: false
    t.string "full_name_hi"
    t.integer "gender", default: 0, null: false
    t.integer "height_cm"
    t.string "job_location"
    t.string "mother_name"
    t.string "mother_occupation"
    t.string "mother_tongue"
    t.string "occupation"
    t.integer "partner_age_max"
    t.integer "partner_age_min"
    t.string "partner_education"
    t.text "partner_expectations"
    t.string "partner_occupation"
    t.datetime "published_at"
    t.text "rejection_reason"
    t.integer "siblings_count", default: 0
    t.string "state"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.boolean "user_consented", default: false, null: false
    t.bigint "user_id", null: false
    t.index ["city"], name: "index_biodatas_on_city"
    t.index ["created_by_id"], name: "index_biodatas_on_created_by_id"
    t.index ["date_of_birth"], name: "index_biodatas_on_date_of_birth"
    t.index ["gender", "status"], name: "index_biodatas_on_gender_and_status"
    t.index ["gender"], name: "index_biodatas_on_gender"
    t.index ["status", "published_at"], name: "index_biodatas_on_status_and_published_at"
    t.index ["status"], name: "index_biodatas_on_status"
    t.index ["user_id"], name: "index_biodatas_on_user_id"
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
    t.text "body", null: false
    t.bigint "commentable_id", null: false
    t.string "commentable_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable_type_and_commentable_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "education_posts", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.integer "category", default: 0, null: false
    t.integer "comments_count", default: 0, null: false
    t.text "content_en", null: false
    t.text "content_hi", null: false
    t.datetime "created_at", null: false
    t.date "exam_date"
    t.integer "likes_count", default: 0, null: false
    t.string "official_url"
    t.string "organization_name"
    t.datetime "published_at"
    t.date "registration_deadline"
    t.integer "status", default: 0, null: false
    t.string "title_en", null: false
    t.string "title_hi", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_education_posts_on_author_id"
    t.index ["category"], name: "index_education_posts_on_category"
    t.index ["published_at"], name: "index_education_posts_on_published_at"
    t.index ["status", "category"], name: "index_education_posts_on_status_and_category"
    t.index ["status", "published_at"], name: "index_education_posts_on_status_and_published_at"
    t.index ["status"], name: "index_education_posts_on_status"
  end

  create_table "job_posts", force: :cascade do |t|
    t.string "application_url"
    t.bigint "author_id", null: false
    t.integer "category", default: 0, null: false
    t.integer "comments_count", default: 0, null: false
    t.string "company_name", null: false
    t.datetime "created_at", null: false
    t.date "deadline"
    t.text "description_en", null: false
    t.text "description_hi", null: false
    t.integer "likes_count", default: 0, null: false
    t.string "location"
    t.datetime "published_at"
    t.integer "status", default: 0, null: false
    t.string "title_en", null: false
    t.string "title_hi", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_job_posts_on_author_id"
    t.index ["category"], name: "index_job_posts_on_category"
    t.index ["published_at"], name: "index_job_posts_on_published_at"
    t.index ["status", "category"], name: "index_job_posts_on_status_and_category"
    t.index ["status", "published_at"], name: "index_job_posts_on_status_and_published_at"
    t.index ["status"], name: "index_job_posts_on_status"
  end

  create_table "likes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "likeable_id", null: false
    t.string "likeable_type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["likeable_type", "likeable_id", "user_id"], name: "index_likes_uniqueness", unique: true
    t.index ["likeable_type", "likeable_id"], name: "index_likes_on_likeable_type_and_likeable_id"
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "magazine_articles", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.text "content_en", null: false
    t.text "content_hi", null: false
    t.datetime "created_at", null: false
    t.bigint "magazine_id", null: false
    t.integer "position", default: 0, null: false
    t.string "title_en", null: false
    t.string "title_hi", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_magazine_articles_on_author_id"
    t.index ["magazine_id", "position"], name: "index_magazine_articles_on_magazine_id_and_position"
    t.index ["magazine_id"], name: "index_magazine_articles_on_magazine_id"
  end

  create_table "magazines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description_en"
    t.text "description_hi"
    t.integer "issue_number", null: false
    t.datetime "published_at"
    t.integer "status", default: 0, null: false
    t.string "title_en", null: false
    t.string "title_hi", null: false
    t.datetime "updated_at", null: false
    t.string "volume"
    t.index ["issue_number"], name: "index_magazines_on_issue_number", unique: true
    t.index ["status", "published_at"], name: "index_magazines_on_status_and_published_at"
    t.index ["status"], name: "index_magazines_on_status"
  end

  create_table "news", force: :cascade do |t|
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
    t.integer "views_count", default: 0, null: false
    t.index ["author_id"], name: "index_news_on_author_id"
    t.index ["category_id"], name: "index_news_on_category_id"
    t.index ["published_at"], name: "index_news_on_published_at"
    t.index ["region_id"], name: "index_news_on_region_id"
    t.index ["status", "published_at"], name: "index_news_on_status_and_published_at"
    t.index ["status"], name: "index_news_on_status"
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.string "browser"
    t.datetime "created_at", null: false
    t.string "platform", default: "web", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["token"], name: "index_push_subscriptions_on_token", unique: true
    t.index ["user_id"], name: "index_push_subscriptions_on_user_id"
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

  create_table "relatives", force: :cascade do |t|
    t.bigint "biodata_id", null: false
    t.datetime "created_at", null: false
    t.string "name"
    t.string "relative_type"
    t.datetime "updated_at", null: false
    t.index ["biodata_id"], name: "index_relatives_on_biodata_id"
  end

  create_table "shortlists", force: :cascade do |t|
    t.bigint "biodata_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["biodata_id"], name: "index_shortlists_on_biodata_id"
    t.index ["user_id", "biodata_id"], name: "index_shortlists_on_user_id_and_biodata_id", unique: true
    t.index ["user_id"], name: "index_shortlists_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.jsonb "allowed_sections", default: [], null: false
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

  create_table "webinars", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description_en", null: false
    t.text "description_hi", null: false
    t.integer "duration_minutes", default: 60, null: false
    t.bigint "host_id", null: false
    t.string "meeting_url"
    t.integer "platform", default: 0, null: false
    t.string "speaker_bio"
    t.string "speaker_name", null: false
    t.datetime "starts_at", null: false
    t.integer "status", default: 0, null: false
    t.string "title_en", null: false
    t.string "title_hi", null: false
    t.datetime "updated_at", null: false
    t.index ["host_id"], name: "index_webinars_on_host_id"
    t.index ["starts_at"], name: "index_webinars_on_starts_at"
    t.index ["status", "starts_at"], name: "index_webinars_on_status_and_starts_at"
    t.index ["status"], name: "index_webinars_on_status"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "biodatas", "users"
  add_foreign_key "comments", "users"
  add_foreign_key "education_posts", "users", column: "author_id"
  add_foreign_key "job_posts", "users", column: "author_id"
  add_foreign_key "likes", "users"
  add_foreign_key "magazine_articles", "magazines"
  add_foreign_key "magazine_articles", "users", column: "author_id"
  add_foreign_key "news", "categories"
  add_foreign_key "news", "regions"
  add_foreign_key "news", "users", column: "author_id"
  add_foreign_key "push_subscriptions", "users"
  add_foreign_key "relatives", "biodatas"
  add_foreign_key "shortlists", "biodatas"
  add_foreign_key "shortlists", "users"
  add_foreign_key "webinars", "users", column: "host_id"
end
