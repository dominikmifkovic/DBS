-- Presunutie exemplára do inej zóny
CREATE OR REPLACE FUNCTION move_exemplar_to_zone() RETURNS TRIGGER AS $$
DECLARE
    exemplar_status current_status_enum;
    zone_exposition INTEGER;
BEGIN
    SELECT current_status INTO exemplar_status FROM exemplars WHERE id = NEW.exemplar_id;
    SELECT exposition_id INTO zone_exposition FROM exposition_zones WHERE zone_id = NEW.zone_id;

    IF zone_exposition IS NULL OR zone_exposition <> (SELECT exposition_id FROM exemplar_expositions WHERE exemplar_id = NEW.exemplar_id) THEN
        RAISE EXCEPTION 'Zóna nepatrí do expozície, v ktorej je exemplár.';
    -- Ak zóna nepatrí do expozície kde je daný exemplár, vypíše sa chyba
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER exemplar_movement BEFORE UPDATE ON exemplars_zones FOR EACH ROW EXECUTE PROCEDURE move_exemplar_to_zone();