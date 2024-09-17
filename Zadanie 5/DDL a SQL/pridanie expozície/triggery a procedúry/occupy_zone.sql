-- Obsadenie zóny pre expozíciu

CREATE OR REPLACE FUNCTION occupy_zone() RETURNS TRIGGER AS $$
DECLARE
    zone_status BOOLEAN;
    first_zone INTEGER;
BEGIN
    SELECT is_occupied INTO zone_status FROM zones WHERE id = NEW.zone_id;
    SELECT COUNT(*) INTO first_zone FROM exposition_zones WHERE exposition_id = NEW.exposition_id;
    IF zone_status = TRUE THEN
        RAISE EXCEPTION 'Zóna je už obsadená.';
        -- Zóna nie je dostupná pre pridanie
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