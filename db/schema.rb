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

ActiveRecord::Schema[8.1].define(version: 2026_03_16_185705) do
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

  create_table "conjurings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "grimoire_text", null: false
    t.integer "project_id", null: false
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.integer "variations_count", null: false
    t.index ["project_id"], name: "index_conjurings_on_project_id"
  end

  create_table "grimoires", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "projects_count", default: 0
    t.datetime "updated_at", null: false
  end

  create_table "projects", force: :cascade do |t|
    t.string "aspect_ratio", default: "16:9"
    t.datetime "created_at", null: false
    t.integer "default_variations", default: 5
    t.integer "grimoire_id", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["grimoire_id"], name: "index_projects_on_grimoire_id"
  end

  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "default_aspect_ratio", default: "16:9"
    t.integer "default_variations", default: 5
    t.string "llm_api_key"
    t.string "nano_banana_api_key"
    t.datetime "updated_at", null: false
  end

  create_table "slides", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "position", null: false
    t.integer "project_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_slides_on_project_id"
  end

  create_table "visions", force: :cascade do |t|
    t.integer "conjuring_id", null: false
    t.datetime "created_at", null: false
    t.integer "position"
    t.text "prompt"
    t.text "refinement"
    t.boolean "selected", default: false
    t.integer "slide_id", null: false
    t.text "slide_text"
    t.datetime "updated_at", null: false
    t.index ["conjuring_id"], name: "index_visions_on_conjuring_id"
    t.index ["slide_id"], name: "index_visions_on_slide_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "conjurings", "projects"
  add_foreign_key "projects", "grimoires"
  add_foreign_key "slides", "projects"
  add_foreign_key "visions", "conjurings"
  add_foreign_key "visions", "slides"
end
