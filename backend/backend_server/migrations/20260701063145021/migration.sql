BEGIN;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_session_log" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_runtime_settings" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_readwrite_test" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_query_log" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_migrations" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_method" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_message_log" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_log" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_health_metric" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_health_connection_info" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_future_call" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_cloud_storage_direct_upload" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_cloud_storage" CASCADE;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "user_info" ADD COLUMN "imagePath" text;

--
-- MIGRATION VERSION FOR backend
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('backend', '20260701063145021', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260701063145021', "timestamp" = now();


--
-- MIGRATION VERSION FOR 'serverpod'
--
DELETE FROM "serverpod_migrations"WHERE "module" IN ('serverpod');

COMMIT;
