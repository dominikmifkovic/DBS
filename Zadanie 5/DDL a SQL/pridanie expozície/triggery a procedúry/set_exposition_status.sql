-- Kontrola a nastavenie statusu expozície pri vkladaní alebo úprave času

CREATE OR REPLACE FUNCTION set_exposition_status() RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.start_date <= NOW() AND NEW.end_date >= NOW()) THEN
        NEW.status := 'IN_PROGRESS';
        UPDATE exemplars SET current_status = 'IN_EXPO' WHERE id IN (SELECT exemplar_id FROM exemplar_expositions WHERE exposition_id = NEW.id);
        UPDATE zones SET is_occupied = TRUE WHERE id IN (SELECT zone_id FROM exposition_zones WHERE exposition_id = NEW.id);
        -- Ak expozícia prebieha
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
		-- Ak expozícia skončila, správanie je rovnaké ako pri vymazaní expozície
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER set_exposition_status BEFORE UPDATE ON expositions FOR EACH ROW EXECUTE PROCEDURE set_exposition_status();
CREATE OR REPLACE TRIGGER set_exposition_status_insert BEFORE INSERT ON expositions FOR EACH ROW EXECUTE PROCEDURE set_exposition_status();
