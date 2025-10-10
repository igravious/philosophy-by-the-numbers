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

ActiveRecord::Schema.define(version: 20251010095418) do

  create_table "actual_texts", force: :cascade do |t|
    t.string   "URL",         limit: 255
    t.integer  "strip_start"
    t.integer  "strip_end"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "what",        limit: 255
  end

  create_table "author_texts", force: :cascade do |t|
    t.integer  "author_id"
    t.integer  "text_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "authors", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.integer  "year_of_birth"
    t.integer  "year_of_death"
    t.string   "where",         limit: 255
    t.text     "about"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "english_name",  limit: 255
    t.string   "date_of_birth", limit: 255
    t.string   "when_died",     limit: 255
  end

  create_table "canonicity_weights", force: :cascade do |t|
    t.string   "algorithm_version",                                        null: false
    t.string   "source_name",                                              null: false
    t.decimal  "weight_value",      precision: 8, scale: 6,                null: false
    t.string   "description"
    t.boolean  "active",                                    default: true
    t.datetime "created_at",                                               null: false
    t.datetime "updated_at",                                               null: false
  end

  add_index "canonicity_weights", ["algorithm_version", "active"], name: "index_canonicity_weights_on_algorithm_version_and_active"
  add_index "canonicity_weights", ["algorithm_version", "source_name"], name: "index_canonicity_weights_on_algorithm_version_and_source_name", unique: true

  create_table "capacities", force: :cascade do |t|
    t.integer  "entity_id"
    t.string   "label"
    t.boolean  "relevant",    default: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "roles_count"
  end

  add_index "capacities", ["entity_id"], name: "index_capacities_on_entity_id", unique: true

  create_table "dictionaries", force: :cascade do |t|
    t.string   "title",             limit: 255
    t.string   "long_title",        limit: 255
    t.string   "URI",               limit: 255
    t.string   "current_editor",    limit: 255
    t.string   "contact",           limit: 255
    t.string   "organisation",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "machine",                       default: false
    t.integer  "entity_id"
    t.float    "dbpedia_pagerank"
    t.integer  "year"
    t.integer  "missing"
    t.string   "content_uri"
    t.string   "encyclopedia_flag"
  end

  create_table "expressions", id: false, force: :cascade do |t|
    t.integer "creator_id", null: false
    t.integer "work_id",    null: false
  end

  add_index "expressions", ["work_id", "creator_id"], name: "index_expressions_on_work_id_and_creator_id", unique: true

  create_table "filters", force: :cascade do |t|
    t.string   "name"
    t.integer  "tag_id"
    t.string   "inequality"
    t.integer  "original_year"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "name_in_english"
  end

  add_index "filters", ["name"], name: "index_filters_on_name", unique: true

  create_table "fyles", force: :cascade do |t|
    t.string   "URL",              limit: 255
    t.string   "what",             limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "type_negotiation", limit: 255
    t.boolean  "handled",                      default: false
    t.integer  "status_code"
    t.string   "cache_file",       limit: 255
    t.string   "encoding",         limit: 255
    t.string   "local_file",       limit: 255
    t.float    "health"
    t.string   "health_hash"
    t.integer  "file_size"
  end

  add_index "fyles", ["URL"], name: "index_fyles_on_URL", unique: true

  create_table "http_request_loggers", force: :cascade do |t|
    t.string   "caller",     limit: 255
    t.string   "uri",        limit: 255
    t.string   "request",    limit: 255
    t.text     "response"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "includings", force: :cascade do |t|
    t.integer  "filter_id",  null: false
    t.integer  "text_id",    null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "includings", ["filter_id", "text_id"], name: "index_includings_on_filter_id_and_text_id", unique: true

  create_table "labelings", force: :cascade do |t|
    t.integer  "tag_id"
    t.integer  "text_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "labelings", ["tag_id", "text_id"], name: "index_labelings_on_tag_id_and_text_id", unique: true

  create_table "links", force: :cascade do |t|
    t.string   "table_name",  limit: 255
    t.integer  "row_id"
    t.string   "IRI",         limit: 255
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "meta_filter_pairs", force: :cascade do |t|
    t.integer  "meta_filter_id", null: false
    t.string   "key",            null: false
    t.string   "value",          null: false
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "meta_filter_pairs", ["meta_filter_id", "key"], name: "index_meta_filter_pairs_on_meta_filter_id_and_key", unique: true

  create_table "meta_filters", force: :cascade do |t|
    t.string   "filter",     null: false
    t.string   "type",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "meta_filters", ["filter"], name: "index_meta_filters_on_filter", unique: true

  create_table "metric_snapshots", force: :cascade do |t|
    t.integer  "shadow_id",                          null: false
    t.datetime "calculated_at",                      null: false
    t.float    "measure"
    t.integer  "measure_pos"
    t.string   "danker_version"
    t.string   "danker_file"
    t.string   "algorithm_version",  default: "1.0"
    t.text     "notes"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.text     "weights_config"
    t.text     "input_values"
    t.float    "danker_score"
    t.text     "encyclopedia_flags"
    t.integer  "linkcount"
    t.integer  "mention_count"
    t.string   "shadow_type",                        null: false
  end

  add_index "metric_snapshots", ["algorithm_version"], name: "index_metric_snapshots_on_algorithm_version"
  add_index "metric_snapshots", ["calculated_at"], name: "index_metric_snapshots_on_calculated_at"
  add_index "metric_snapshots", ["shadow_type", "shadow_id", "calculated_at"], name: "index_metric_snapshots_on_shadow_and_calculated_at"
  add_index "metric_snapshots", ["shadow_type", "shadow_id"], name: "index_metric_snapshots_on_shadow_type_and_shadow_id"

  create_table "names", force: :cascade do |t|
    t.integer  "shadow_id",  null: false
    t.string   "label"
    t.string   "lang"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "langorder"
  end

  add_index "names", ["label"], name: "index_names_on_label"
  add_index "names", ["shadow_id", "lang"], name: "index_names_on_shadow_id_and_lang", unique: true

  create_table "obsolete_attrs", force: :cascade do |t|
    t.integer  "shadow_id",                        null: false
    t.string   "shadow_type",                      null: false
    t.float    "metric"
    t.integer  "metric_pos"
    t.float    "dbpedia_pagerank"
    t.boolean  "oxford",           default: false
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
  end

  add_index "obsolete_attrs", ["shadow_id", "shadow_type"], name: "index_obsolete_attrs_on_shadow_id_and_shadow_type"
  add_index "obsolete_attrs", ["shadow_id"], name: "index_obsolete_attrs_on_shadow_id"

  create_table "p_smarts", id: false, force: :cascade do |t|
    t.integer "entity_id"
    t.integer "redirect_id"
    t.integer "object_id"
    t.string  "object_label"
    t.string  "type"
  end

  add_index "p_smarts", ["redirect_id", "object_id", "type"], name: "index_p_smarts_on_redirect_id_and_object_id_and_type", unique: true

  create_table "philosopher_attrs", force: :cascade do |t|
    t.integer  "shadow_id",                    null: false
    t.string   "birth"
    t.boolean  "birth_approx", default: false
    t.integer  "birth_year"
    t.string   "death"
    t.boolean  "death_approx", default: false
    t.integer  "death_year"
    t.string   "floruit"
    t.string   "period"
    t.boolean  "dbpedia",      default: false
    t.boolean  "oxford2",      default: false
    t.boolean  "oxford3",      default: false
    t.boolean  "stanford",     default: false
    t.boolean  "internet",     default: false
    t.boolean  "kemerling",    default: false
    t.boolean  "runes",        default: false
    t.boolean  "populate",     default: false
    t.integer  "inpho",        default: 0
    t.boolean  "inphobool",    default: false
    t.string   "gender"
    t.integer  "philosopher",  default: 0
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "philosopher_attrs", ["shadow_id"], name: "index_philosopher_attrs_on_shadow_id", unique: true

  create_table "properties", force: :cascade do |t|
    t.integer  "property_id"
    t.integer  "entity_id"
    t.string   "entity_label"
    t.integer  "data_id"
    t.string   "data_label"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.integer  "instance_id"
    t.string   "instance_label"
    t.integer  "original_id"
    t.integer  "inferred_id"
    t.string   "inferred_label"
  end

  add_index "properties", ["property_id", "entity_id", "data_id"], name: "index_properties_on_property_id_and_entity_id_and_data_id", unique: true

  create_table "resources", force: :cascade do |t|
    t.string   "URI",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", force: :cascade do |t|
    t.integer  "shadow_id"
    t.integer  "entity_id"
    t.string   "label"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "roles", ["entity_id"], name: "index_roles_on_entity_id"

  create_table "shadows", force: :cascade do |t|
    t.string   "type"
    t.integer  "entity_id"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "linkcount"
    t.integer  "philosophy"
    t.boolean  "routledge",   default: false
    t.string   "date_hack"
    t.string   "viaf"
    t.string   "what_label"
    t.string   "name_hack"
    t.boolean  "cambridge",   default: false
    t.boolean  "borchert",    default: false
    t.float    "measure"
    t.integer  "measure_pos"
    t.float    "danker"
    t.integer  "mention",     default: 0,     null: false
    t.string   "country"
  end

  add_index "shadows", ["entity_id"], name: "index_shadows_on_entity_id", unique: true

  create_table "tags", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "tags", ["name"], name: "index_tags_on_name", unique: true

  create_table "texts", force: :cascade do |t|
    t.string   "name",              limit: 255
    t.integer  "original_year"
    t.integer  "edition_year"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name_in_english",   limit: 255
    t.integer  "fyle_id"
    t.boolean  "include",                       default: false
    t.string   "original_language", limit: 255
  end

  add_index "texts", ["name_in_english", "original_year"], name: "index_texts_on_name_in_english_and_original_year", unique: true

  create_table "units", force: :cascade do |t|
    t.integer  "dictionary_id"
    t.string   "entry",         limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "normal_form"
    t.string   "analysis"
    t.boolean  "confirmation",              default: false
    t.string   "what_it_is"
    t.string   "display_name"
  end

  create_table "viaf_cache_items", id: false, force: :cascade do |t|
    t.string "personal"
    t.string "uniform_title_work"
    t.string "q"
    t.string "url"
  end

  add_index "viaf_cache_items", ["personal", "uniform_title_work"], name: "index_viaf_cache_items_on_personal_and_uniform_title_work", unique: true

  create_table "work_attrs", force: :cascade do |t|
    t.integer  "shadow_id",                     null: false
    t.string   "pub"
    t.string   "pub_year"
    t.string   "pub_approx"
    t.string   "work_lang"
    t.string   "copyright"
    t.boolean  "genre",         default: false, null: false
    t.boolean  "obsolete",      default: false, null: false
    t.string   "philrecord"
    t.string   "philtopic"
    t.string   "britannica"
    t.string   "image"
    t.integer  "philosophical"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "work_attrs", ["shadow_id"], name: "index_work_attrs_on_shadow_id", unique: true

  create_table "writings", force: :cascade do |t|
    t.integer  "author_id"
    t.integer  "text_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "role"
  end

  add_index "writings", ["author_id", "text_id"], name: "index_writings_on_author_id_and_text_id", unique: true

end
