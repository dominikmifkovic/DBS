-- Pridanie exempláru do expozície

CREATE OR REPLACE FUNCTION add_exemplar_to_exposition() RETURNS TRIGGER AS $$
DECLARE
    exemplar_status current_status_enum;
BEGIN
    SELECT current_status INTO exemplar_status FROM exemplars WHERE id = NEW.exemplar_id;
    IF exemplar_status <> 'IN_STORAGE' THEN 
        RAISE EXCEPTION 'Exemplár nie je dostupný pre pridanie do expozície.'; 
        -- Ak exemplár nemá status IN_STORAGE, znamená to, že nie je dostupný 
    ELSE
        UPDATE exemplars SET current_status = 'IN_EXPO' WHERE id = NEW.exemplar_id;
        RETURN NEW;
        -- Exempláru sa nastaví status IN_EXPO
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER exemplar_status_check BEFORE INSERT OR UPDATE ON exemplar_expositions
FOR EACH ROW EXECUTE PROCEDURE add_exemplar_to_exposition();