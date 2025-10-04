CREATE TABLE "actual_texts" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "URL" varchar(255), "strip_start" integer, "strip_end" integer, "created_at" datetime, "updated_at" datetime, "what" varchar(255));
CREATE TABLE "author_texts" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "author_id" integer, "text_id" integer, "created_at" datetime, "updated_at" datetime);
CREATE TABLE "authors" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar(255), "year_of_birth" integer, "year_of_death" integer, "where" varchar(255), "about" text, "created_at" datetime, "updated_at" datetime, "english_name" varchar(255), "date_of_birth" varchar(255), "when_died" varchar(255));
CREATE TABLE "dictionaries" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "title" varchar(255), "long_title" varchar(255), "URI" varchar(255), "current_editor" varchar(255), "contact" varchar(255), "organisation" varchar(255), "created_at" datetime, "updated_at" datetime, "machine" boolean DEFAULT 'f');
CREATE TABLE "entries" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "dictionary_id" integer, "label" varchar(255), "body" text, "created_at" datetime, "updated_at" datetime);
CREATE TABLE "fyles" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "URL" varchar(255), "what" varchar(255), "strip_start" integer, "strip_end" integer, "created_at" datetime, "updated_at" datetime, "type_negotiation" integer(255), "handled" boolean DEFAULT 'f', "status_code" integer, "cache_file" varchar(255), "encoding" varchar(255), "local_file" varchar(255));
CREATE TABLE "http_request_loggers" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "caller" varchar(255), "uri" varchar(255), "request" varchar(255), "response" text, "created_at" datetime, "updated_at" datetime);
CREATE TABLE "links" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "table_name" varchar(255), "row_id" integer, "IRI" varchar(255), "description" text, "created_at" datetime, "updated_at" datetime);
CREATE TABLE "resources" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "URI" varchar(255), "created_at" datetime, "updated_at" datetime);
CREATE TABLE "schema_migrations" ("version" varchar(255) NOT NULL);
CREATE TABLE "texts" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar(255), "original_year" integer, "edition_year" integer, "created_at" datetime, "updated_at" datetime, "name_in_english" varchar(255), "fyle_id" integer, "include" boolean DEFAULT 'f', "original_language" varchar(255));
CREATE TABLE "units" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "dictionary_id" integer, "entry" varchar(255), "created_at" datetime, "updated_at" datetime, "normal_form" varchar, "analysis" varchar, "class" varchar, "confirmation" boolean DEFAULT 'f');
CREATE TABLE "writings" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "author_id" integer, "text_id" integer, "created_at" datetime, "updated_at" datetime, "role" integer);
CREATE UNIQUE INDEX "index_fyles_on_URL" ON "fyles" ("URL");
CREATE UNIQUE INDEX "index_texts_on_name_in_english_and_original_year" ON "texts" ("name_in_english", "original_year");
CREATE UNIQUE INDEX "index_writings_on_author_id_and_text_id" ON "writings" ("author_id", "text_id");
CREATE UNIQUE INDEX "unique_schema_migrations" ON "schema_migrations" ("version");
INSERT INTO schema_migrations (version) VALUES ('20150602092636');

INSERT INTO schema_migrations (version) VALUES ('20150602092658');

INSERT INTO schema_migrations (version) VALUES ('20150602092719');

INSERT INTO schema_migrations (version) VALUES ('20150602092740');

INSERT INTO schema_migrations (version) VALUES ('20150602115119');

INSERT INTO schema_migrations (version) VALUES ('20150602174614');

INSERT INTO schema_migrations (version) VALUES ('20150602191156');

INSERT INTO schema_migrations (version) VALUES ('20150603105614');

INSERT INTO schema_migrations (version) VALUES ('20150603105628');

INSERT INTO schema_migrations (version) VALUES ('20150603110549');

INSERT INTO schema_migrations (version) VALUES ('20150603113904');

INSERT INTO schema_migrations (version) VALUES ('20150603124448');

INSERT INTO schema_migrations (version) VALUES ('20150604040209');

INSERT INTO schema_migrations (version) VALUES ('20150604042412');

INSERT INTO schema_migrations (version) VALUES ('20150604062909');

INSERT INTO schema_migrations (version) VALUES ('20150605162924');

INSERT INTO schema_migrations (version) VALUES ('20150605215625');

INSERT INTO schema_migrations (version) VALUES ('20150605222519');

INSERT INTO schema_migrations (version) VALUES ('20150606092620');

INSERT INTO schema_migrations (version) VALUES ('20150606094448');

INSERT INTO schema_migrations (version) VALUES ('20150606133004');

INSERT INTO schema_migrations (version) VALUES ('20150608171903');

INSERT INTO schema_migrations (version) VALUES ('20150613073845');

INSERT INTO schema_migrations (version) VALUES ('20150613102431');

INSERT INTO schema_migrations (version) VALUES ('20150614091210');

INSERT INTO schema_migrations (version) VALUES ('20150617141523');

INSERT INTO schema_migrations (version) VALUES ('20150620152849');

INSERT INTO schema_migrations (version) VALUES ('20150622112316');

INSERT INTO schema_migrations (version) VALUES ('20150626155250');

INSERT INTO schema_migrations (version) VALUES ('20150627081049');

INSERT INTO schema_migrations (version) VALUES ('20151129155121');

INSERT INTO schema_migrations (version) VALUES ('20151129155202');

INSERT INTO schema_migrations (version) VALUES ('20160123212551');

INSERT INTO schema_migrations (version) VALUES ('20160917153749');

INSERT INTO schema_migrations (version) VALUES ('20160923202721');

INSERT INTO schema_migrations (version) VALUES ('20160924201917');

INSERT INTO schema_migrations (version) VALUES ('20160925152158');

INSERT INTO schema_migrations (version) VALUES ('20160925152335');

