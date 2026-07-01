BEGIN;

--
-- Class ExpenseEntry as table expense_entry
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
-- Class User as table user_info
--
CREATE TABLE "user_info" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "email" text NOT NULL,
    "imagePath" text,
    "password" text NOT NULL,
    "createdAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "user_email_idx" ON "user_info" USING btree ("email");


--
-- MIGRATION VERSION FOR backend
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('backend', '20260701063145021', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260701063145021', "timestamp" = now();


COMMIT;
