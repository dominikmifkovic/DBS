ALTER TABLE IF EXISTS exemplars_zones DROP CONSTRAINT IF EXISTS exemplars_zones_exemplar_id_fkey;
ALTER TABLE IF EXISTS exemplars_zones DROP CONSTRAINT IF EXISTS exemplars_zones_zone_id_fkey;
ALTER TABLE IF EXISTS loans DROP CONSTRAINT IF EXISTS loans_exemplar_id_fkey;
ALTER TABLE IF EXISTS loans DROP CONSTRAINT IF EXISTS loans_involved_institution_id_fkey;
ALTER TABLE IF EXISTS after_loan_inspection DROP CONSTRAINT IF EXISTS after_loan_inspection_loan_id_fkey;
ALTER TABLE IF EXISTS exemplar_expositions DROP CONSTRAINT IF EXISTS exemplar_expositions_exemplar_id_fkey;
ALTER TABLE IF EXISTS exemplar_expositions DROP CONSTRAINT IF EXISTS exemplar_expositions_exposition_id_fkey;
ALTER TABLE IF EXISTS exposition_zones DROP CONSTRAINT IF EXISTS exposition_zones_exposition_id_fkey;
ALTER TABLE IF EXISTS exposition_zones DROP CONSTRAINT IF EXISTS exposition_zones_zone_id_fkey;

DROP TABLE IF EXISTS exemplars_zones;
DROP TABLE IF EXISTS loans;
DROP TABLE IF EXISTS after_loan_inspection;
DROP TABLE IF EXISTS exemplar_expositions;
DROP TABLE IF EXISTS exposition_zones;
DROP TABLE IF EXISTS exemplars;
DROP TABLE IF EXISTS expositions;
DROP TABLE IF EXISTS zones;
DROP TABLE IF EXISTS institutions;
DROP TABLE IF EXISTS categories;

DROP TYPE IF EXISTS ownership_status_enum;
DROP TYPE IF EXISTS current_status_enum;
DROP TYPE IF EXISTS exposition_status_enum;
DROP TYPE IF EXISTS loan_type_enum;

CREATE TYPE "ownership_status_enum" AS ENUM (
	'OWNED',
	'LOANED'
);

CREATE TYPE "current_status_enum" AS ENUM (
	'IN_STORAGE',
	'IN_EXPO',
	'BEING_INSPECTED',
	'IN_TRANSIT',
	'NONE'
);

CREATE TYPE "exposition_status_enum" AS ENUM (
	'PLANNED',
	'IN_PROGRESS',
	'ENDED'
);

CREATE TYPE "loan_type_enum" AS ENUM (
	'LOANED_TO',
	'LOANED_IN'
);

CREATE TABLE "categories" (
	"id" SERIAL PRIMARY KEY,
	"name" TEXT UNIQUE
);

CREATE TABLE "exemplars" (
	"id" SERIAL PRIMARY KEY,
	"category_id" INTEGER REFERENCES "categories" ("id"),
	"name" TEXT UNIQUE,
	"description" TEXT,
	"ownership_status" ownership_status_enum DEFAULT 'OWNED',
	"current_status" current_status_enum DEFAULT 'IN_STORAGE',
	CONSTRAINT compatible_ownership_status CHECK (
	(ownership_status = 'OWNED' AND current_status IN ('IN_STORAGE', 'IN_EXPO', 'BEING_INSPECTED'))
	OR (ownership_status = 'LOANED' AND current_status IN ('IN_STORAGE', 'IN_EXPO', 'BEING_INSPECTED', 'IN_TRANSIT')))
);

CREATE TABLE "expositions" (
	"id" SERIAL PRIMARY KEY,
	"name" TEXT UNIQUE,
	"start_date" TIMESTAMP,
	"end_date" TIMESTAMP,
	"status" exposition_status_enum DEFAULT 'PLANNED'
);

CREATE TABLE "zones" (
	"id" SERIAL PRIMARY KEY,
	"name" TEXT,
	"is_occupied" BOOLEAN DEFAULT FALSE
);


CREATE TABLE "exemplars_zones" (
	"exemplar_id" INTEGER REFERENCES "exemplars" ("id") ON DELETE CASCADE ON UPDATE CASCADE UNIQUE,
	"zone_id" INTEGER REFERENCES "zones" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE "institutions" (
	"id" SERIAL PRIMARY KEY,
	"name" TEXT UNIQUE
);

CREATE TABLE "loans" (
	"id" SERIAL PRIMARY KEY,
	"exemplar_id" INTEGER REFERENCES "exemplars" ("id"),
	"type" loan_type_enum DEFAULT 'LOANED_TO',
	"involved_institution_id" INTEGER REFERENCES "institutions" ("id"),
	"loan_start_date" TIMESTAMP,
	"loan_end_date" TIMESTAMP,
	"expected_exemplar_availability" TIMESTAMP
);


CREATE TABLE "after_loan_inspection" (
	"id" SERIAL PRIMARY KEY,
	"loan_id" INTEGER REFERENCES "loans" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
	"inspection_date" TIMESTAMP,
	"inspection_end_date" TIMESTAMP,
	"inspection_description" TEXT
);

CREATE TABLE "exemplar_expositions" (
	"exemplar_id" INTEGER REFERENCES "exemplars" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
	"exposition_id" INTEGER REFERENCES "expositions" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
	PRIMARY KEY ("exemplar_id", "exposition_id")
);

CREATE TABLE "exposition_zones" (
	"exposition_id" INTEGER REFERENCES "expositions" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
	"zone_id" INTEGER REFERENCES "zones" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
	PRIMARY KEY ("exposition_id", "zone_id"),
	CONSTRAINT one_exp_per_zone UNIQUE (zone_id)
);
		

-- Pridanie kategórií
INSERT INTO categories (name) VALUES ('Maľba');
INSERT INTO categories (name) VALUES ('Socha');
INSERT INTO categories (name) VALUES ('Fotografia');

--Pridanie inštitúcií
INSERT INTO institutions (name) VALUES ('Inštitúcia 1');
INSERT INTO institutions (name) VALUES ('Inštitúcia 2');
INSERT INTO institutions (name) VALUES ('Inštitúcia 3');

-- Pridanie zón
INSERT INTO zones (name) VALUES ('Zóna 1');
INSERT INTO zones (name) VALUES ('Zóna 2');
INSERT INTO zones (name) VALUES ('Zóna 3');

-- Pridanie exemplárov
INSERT INTO exemplars (category_id, name, description, ownership_status, current_status)
VALUES ((SELECT id FROM categories WHERE name = 'Maľba'), 'Maľba 1', 'Popis maľby 1', 'OWNED', 'IN_STORAGE');
INSERT INTO exemplars (category_id, name, description, ownership_status, current_status)
VALUES ((SELECT id FROM categories WHERE name = 'Socha'), 'Socha 1', 'Popis sochy 1', 'OWNED', 'IN_STORAGE');
INSERT INTO exemplars (category_id, name, description, ownership_status, current_status)
VALUES ((SELECT id FROM categories WHERE name = 'Fotografia'), 'Fotografia 1', 'Popis fotografie 1', 'OWNED', 'IN_STORAGE');