ALTER TABLE IF EXISTS exemplars_zones DROP CONSTRAINT IF EXISTS exemplars_zones_exemplar_id_fkey;
ALTER TABLE IF EXISTS exemplars_zones DROP CONSTRAINT IF EXISTS exemplars_zones_zone_id_fkey;
ALTER TABLE IF EXISTS loans DROP CONSTRAINT IF EXISTS loans_exemplar_id_fkey;
ALTER TABLE IF EXISTS loans DROP CONSTRAINT IF EXISTS loans_involved_institution_id_fkey;
ALTER TABLE IF EXISTS after_loan_inspection DROP CONSTRAINT IF EXISTS after_loan_inspection_loan_id_fkey;
ALTER TABLE IF EXISTS exemplar_expositions DROP CONSTRAINT IF EXISTS exemplar_expositions_exemplar_id_fkey;
ALTER TABLE IF EXISTS exemplar_expositions DROP CONSTRAINT IF EXISTS exemplar_expositions_exposition_id_fkey;
ALTER TABLE IF EXISTS exposition_zones DROP CONSTRAINT IF EXISTS exposition_zones_exposition_id_fkey;
ALTER TABLE IF EXISTS exposition_zones DROP CONSTRAINT IF EXISTS exposition_zones_zone_id_fkey;

-- Drop tables
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

-- Drop enums
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

CREATE OR REPLACE FUNCTION create_exposition(exp_name TEXT, exemplare TEXT[], zony TEXT[], start_date TIMESTAMP, end_date TIMESTAMP) RETURNS VOID AS $$
DECLARE
    expo_id INTEGER;
    exemplar_name TEXT;
    zone_name TEXT;
BEGIN
    -- Vytvorenie novej expozície
    INSERT INTO expositions (name, start_date, end_date)
    VALUES (exp_name, start_date, end_date);

    -- Získanie ID novej expozície
    SELECT id INTO expo_id FROM expositions WHERE name = exp_name;

    -- Pridanie exemplárov do expozície
    FOR i IN 1..array_length(exemplare, 1) LOOP
        exemplar_name := exemplare[i];
        INSERT INTO exemplar_expositions (exemplar_id, exposition_id)
        VALUES ((SELECT id FROM exemplars WHERE name = exemplar_name), expo_id);
    END LOOP;

    -- Obsadenie zón
    FOR j IN 1..array_length(zony, 1) LOOP
        zone_name := zony[j];
        INSERT INTO exposition_zones (exposition_id, zone_id)
        VALUES (expo_id, (SELECT id FROM zones WHERE name = zone_name));
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Trigger pre pridanie exemplára do expozície
CREATE OR REPLACE FUNCTION add_exemplar_to_exposition() RETURNS TRIGGER AS $$
DECLARE
    exemplar_status current_status_enum;
BEGIN
    SELECT current_status INTO exemplar_status FROM exemplars WHERE id = NEW.exemplar_id;
    IF exemplar_status <> 'IN_STORAGE' THEN
        RAISE EXCEPTION 'Exemplár nie je dostupný pre pridanie do expozície.';
    ELSE
        UPDATE exemplars SET current_status = 'IN_EXPO' WHERE id = NEW.exemplar_id;
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER exemplar_status_check BEFORE INSERT OR UPDATE ON exemplar_expositions
FOR EACH ROW EXECUTE PROCEDURE add_exemplar_to_exposition();

-- Trigger pre obsadenie zóny
CREATE OR REPLACE FUNCTION occupy_zone() RETURNS TRIGGER AS $$
DECLARE
    zone_status BOOLEAN;
    first_zone INTEGER;
BEGIN
    SELECT is_occupied INTO zone_status FROM zones WHERE id = NEW.zone_id;
    SELECT COUNT(*) INTO first_zone FROM exposition_zones WHERE exposition_id = NEW.exposition_id;
    IF zone_status = TRUE THEN
        RAISE EXCEPTION 'Zóna je už obsadená.';
    ELSE
        UPDATE zones SET is_occupied = TRUE WHERE id = NEW.zone_id;

        -- Pridanie exemplárov expozície do zóny len ak je to prvá pridávaná zóna
        IF first_zone = 0 THEN
            INSERT INTO exemplars_zones (exemplar_id, zone_id)
            SELECT exemplar_id, NEW.zone_id FROM exemplar_expositions WHERE exposition_id = NEW.exposition_id;
        END IF;

        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER zone_occupancy_check BEFORE INSERT ON exposition_zones
FOR EACH ROW EXECUTE PROCEDURE occupy_zone();

-- Funkcia a trigger pre nastavenie stavu expozície pri vložení alebo aktualizácii
CREATE OR REPLACE FUNCTION set_exposition_status() RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.start_date <= NOW() AND NEW.end_date >= NOW()) THEN
        NEW.status := 'IN_PROGRESS';
        UPDATE exemplars SET current_status = 'IN_EXPO' WHERE id IN (SELECT exemplar_id FROM exemplar_expositions WHERE exposition_id = NEW.id);
        UPDATE zones SET is_occupied = TRUE WHERE id IN (SELECT zone_id FROM exposition_zones WHERE exposition_id = NEW.id);
    ELSIF (NEW.end_date < NOW()) THEN
		NEW.status := 'ENDED';
		DELETE FROM exemplars_zones WHERE exemplar_id IN (SELECT exemplar_id FROM exemplar_expositions WHERE exposition_id = NEW.id);
		DELETE FROM exemplar_expositions WHERE exposition_id = NEW.id;
		DELETE FROM exposition_zones WHERE exposition_id = NEW.id;
		UPDATE exemplars SET current_status = 'IN_STORAGE' WHERE id IN (
			SELECT id FROM exemplars WHERE current_status = 'IN_EXPO' AND id NOT IN (
				SELECT exemplar_id FROM exemplar_expositions
			)
		);
        UPDATE zones SET is_occupied = FALSE WHERE id IN (
			SELECT id FROM zones WHERE is_occupied = TRUE AND id NOT IN (
				SELECT zone_id FROM exposition_zones
			)
    	);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER set_exposition_status BEFORE UPDATE ON expositions FOR EACH ROW EXECUTE PROCEDURE set_exposition_status();
CREATE OR REPLACE TRIGGER set_exposition_status_insert BEFORE INSERT ON expositions FOR EACH ROW EXECUTE PROCEDURE set_exposition_status();

CREATE OR REPLACE FUNCTION delete_exposition() RETURNS TRIGGER AS $$
BEGIN
    -- Nastavenie exemplárov späť na 'IN_STORAGE'
	DELETE FROM exemplar_expositions WHERE exposition_id = OLD.id;
    DELETE FROM exposition_zones WHERE exposition_id = OLD.id;
    UPDATE exemplars SET current_status = 'IN_STORAGE' WHERE id IN (
        SELECT id FROM exemplars WHERE current_status = 'IN_EXPO' AND id NOT IN (
            SELECT exemplar_id FROM exemplar_expositions
        )
    );

    -- Nastavenie zón späť na neobsadené
    UPDATE zones SET is_occupied = FALSE WHERE id IN (
        SELECT id FROM zones WHERE is_occupied = TRUE AND id NOT IN (
            SELECT zone_id FROM exposition_zones
        )
    );

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE TRIGGER exposition_deletion AFTER DELETE ON expositions FOR EACH ROW EXECUTE PROCEDURE delete_exposition();

-- Funkcia a trigger pre presunutie exemplára do inej zóny
CREATE OR REPLACE FUNCTION move_exemplar_to_zone() RETURNS TRIGGER AS $$
DECLARE
    exemplar_status current_status_enum;
    zone_exposition INTEGER;
BEGIN
    SELECT current_status INTO exemplar_status FROM exemplars WHERE id = NEW.exemplar_id;
    SELECT exposition_id INTO zone_exposition FROM exposition_zones WHERE zone_id = NEW.zone_id;
    IF zone_exposition IS NULL OR zone_exposition <> (SELECT exposition_id FROM exemplar_expositions WHERE exemplar_id = NEW.exemplar_id) THEN
        RAISE EXCEPTION 'Zóna nepatrí do expozície, v ktorej je exemplár.';
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER exemplar_movement BEFORE UPDATE ON exemplars_zones FOR EACH ROW EXECUTE PROCEDURE move_exemplar_to_zone();


CREATE OR REPLACE FUNCTION receive_exemplar() RETURNS TRIGGER AS $$
DECLARE
    loan_record INTEGER;
	loan_type TEXT;
BEGIN
    SELECT COUNT(*) INTO loan_record FROM loans WHERE exemplar_id = NEW.id AND type = 'LOANED_TO';
	SELECT type INTO loan_type FROM loans WHERE exemplar_id = NEW.id;
    IF (loan_record = 0 AND loan_type <> 'LOANED_IN') OR (OLD.ownership_status = 'LOANED' AND NEW.ownership_status <> 'LOANED') THEN
        -- Exemplár nebol zapožičaný, takže sa vytvorí záznam s ownership_status = 'OWNED'
        NEW.ownership_status := 'OWNED';
	ELSIF loan_type <> 'LOANED_IN' THEN
		NEW.ownership_status := 'LOANED';        
    END IF;
	INSERT INTO after_loan_inspection (loan_id, inspection_date, inspection_end_date, inspection_description)
    VALUES ((SELECT id FROM loans WHERE exemplar_id = NEW.id), NOW(), NOW() + INTERVAL '5 days', 'FINE');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER exemplar_reception BEFORE UPDATE ON exemplars FOR EACH ROW WHEN (OLD.ownership_status = 'LOANED') EXECUTE PROCEDURE receive_exemplar();


CREATE OR REPLACE FUNCTION loan_to(exemplar_name TEXT, institution_name TEXT, start_date TIMESTAMP, end_date TIMESTAMP, available TIMESTAMP) RETURNS VOID AS $$
BEGIN
    UPDATE exemplars 
    SET ownership_status = 'LOANED', current_status = 'IN_TRANSIT' 
    WHERE name = exemplar_name;

    INSERT INTO loans (exemplar_id, type, involved_institution_id, loan_start_date, loan_end_date, expected_exemplar_availability) 
    VALUES (
        (SELECT id FROM exemplars WHERE name = exemplar_name), 
        'LOANED_TO', 
        (SELECT id FROM institutions WHERE name = institution_name), 
        start_date, 
        end_date, 
        available
    );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION loan_to_returned(exemplar_name TEXT) RETURNS VOID AS $$
BEGIN
    UPDATE exemplars 
    SET ownership_status = 'OWNED', current_status = 'BEING_INSPECTED' 
    WHERE name = exemplar_name;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION end_inspection(exemplar_name TEXT) RETURNS VOID AS $$
BEGIN
    UPDATE exemplars 
    SET ownership_status = 'OWNED', current_status = 'IN_STORAGE' 
    WHERE name = exemplar_name;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION loan_from(
    in_category_name TEXT,
    in_exemplar_name TEXT,
    in_description TEXT,
    in_involved_institution_name TEXT,
    in_loan_start_date TIMESTAMP,
    in_loan_end_date TIMESTAMP,
    in_expected_availability TIMESTAMP
) RETURNS VOID AS $$
DECLARE
    v_category_id INTEGER;
    v_involved_institution_id INTEGER;
    v_exemplar_id INTEGER;
BEGIN
    -- Vloženie nového exemplára
    INSERT INTO exemplars (category_id, name, description, ownership_status, current_status)
    VALUES ((SELECT id FROM categories WHERE name = in_category_name), 
            in_exemplar_name, 
            in_description, 
            'LOANED', 
            'IN_TRANSIT');

    -- Získanie ID vloženého exemplára
    SELECT id INTO v_exemplar_id FROM exemplars WHERE name = in_exemplar_name;

    -- Vloženie nového záznamu o pôžičke
    INSERT INTO loans (exemplar_id, type, involved_institution_id, loan_start_date, loan_end_date, expected_exemplar_availability)
    VALUES (v_exemplar_id,
            'LOANED_IN',
            (SELECT id FROM institutions WHERE name = in_involved_institution_name),
            in_loan_start_date,
            in_loan_end_date,
            in_expected_availability);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION loan_arrived(exemplar_name TEXT) RETURNS VOID AS $$
BEGIN
    UPDATE exemplars 
    SET ownership_status = 'LOANED', current_status = 'IN_STORAGE' 
    WHERE name = exemplar_name;
END;
$$ LANGUAGE plpgsql;


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

SELECT create_exposition('PLANNED EXPO'::text, ARRAY['Maľba 1'],  ARRAY['Zóna 1'], '2025-01-01'::timestamp, '2025-01-02'::timestamp);
SELECT create_exposition('IN PROGRESS EXPO'::text, ARRAY['Fotografia 1'],  ARRAY['Zóna 2'], '2023-01-01'::timestamp, '2024-10-10'::timestamp);

DO $$
DECLARE
    expo_id INTEGER;
BEGIN
SELECT id INTO expo_id FROM expositions WHERE name = 'IN PROGRESS EXPO';
INSERT INTO exposition_zones (exposition_id, zone_id)
    VALUES (expo_id, (SELECT id FROM zones WHERE name = 'Zóna 3'));
END $$;


UPDATE expositions SET start_date = '2024-01-01' WHERE name = 'PLANNED EXPO';
UPDATE expositions SET end_date = '2024-03-01' WHERE name = 'IN PROGRESS EXPO';


UPDATE exemplars_zones SET zone_id = 3 WHERE exemplar_id IN (SELECT id FROM exemplars WHERE name = 'Maľba 1');
UPDATE exemplars_zones SET zone_id = 3 WHERE exemplar_id IN (SELECT id FROM exemplars WHERE name = 'Fotografia 1');

INSERT INTO exemplars (category_id, name, description, ownership_status, current_status)
VALUES ((SELECT id FROM categories WHERE name = 'Socha'), 'POZICANIE', 'Popis', 'OWNED', 'IN_STORAGE');
SELECT * FROM exemplars;

-- Požičanie exempláru
SELECT loan_to('POZICANIE'::text, 'Inštitúcia 1'::text, NOW()::TIMESTAMP, NOW()::TIMESTAMP + INTERVAL '5 days' , NOW()::TIMESTAMP + INTERVAL '5 days');

-- Prevzatie exempláru
SELECT loan_to_returned('POZICANIE'::text);

SELECT end_inspection('POZICANIE'::text);

SELECT loan_from(
    'Socha'::text, 
    'ZAPOZICANE'::text, 
    'Popis'::text,  
    'Inštitúcia 1'::text,  
    NOW()::timestamp, 
    NOW()::timestamp + INTERVAL '5 days', 
    NOW()::timestamp  
);

SELECT loan_arrived('ZAPOZICANE'::text);


