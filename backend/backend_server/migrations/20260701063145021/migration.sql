BEGIN;

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




COMMIT;
