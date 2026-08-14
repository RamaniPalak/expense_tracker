BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "goal_contribution_entry" (
    "id" bigserial PRIMARY KEY,
    "goalId" bigint NOT NULL,
    "amount" double precision NOT NULL,
    "date" timestamp without time zone NOT NULL,
    "note" text,
    "type" text NOT NULL,
    "userEmail" text NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "goal_entry" (
    "id" bigserial PRIMARY KEY,
    "title" text NOT NULL,
    "targetAmount" double precision NOT NULL,
    "currentAmount" double precision NOT NULL,
    "targetDate" timestamp without time zone NOT NULL,
    "iconCode" bigint NOT NULL,
    "colorValue" bigint NOT NULL,
    "category" text NOT NULL,
    "userEmail" text NOT NULL,
    "priority" text NOT NULL,
    "status" text NOT NULL,
    "productUrl" text,
    "autoDepositAmount" double precision NOT NULL,
    "autoDepositDay" bigint NOT NULL
);


--
-- MIGRATION VERSION FOR backend
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('backend', '20260814131047684', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260814131047684', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
