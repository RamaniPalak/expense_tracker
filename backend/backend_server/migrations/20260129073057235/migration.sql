BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "expense_entry" (
    "id" bigserial PRIMARY KEY,
    "title" text NOT NULL,
    "amount" double precision NOT NULL,
    "date" timestamp without time zone NOT NULL,
    "category" text NOT NULL,
    "isIncome" boolean NOT NULL,
    "userEmail" text NOT NULL
);


--
-- MIGRATION VERSION FOR backend
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('backend', '20260129073057235', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129073057235', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
