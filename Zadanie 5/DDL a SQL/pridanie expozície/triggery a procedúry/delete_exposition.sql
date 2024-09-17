-- Vymazanie expozície

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