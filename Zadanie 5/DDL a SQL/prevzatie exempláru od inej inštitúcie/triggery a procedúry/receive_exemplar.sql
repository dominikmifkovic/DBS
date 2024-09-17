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
    -- Vytvorenie záznamu o inšpekcii
	INSERT INTO after_loan_inspection (loan_id, inspection_date, inspection_end_date, inspection_description)
    VALUES ((SELECT id FROM loans WHERE exemplar_id = NEW.id), NOW(), NOW() + INTERVAL '5 days', 'FINE');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER exemplar_reception BEFORE UPDATE ON exemplars FOR EACH ROW WHEN (OLD.ownership_status = 'LOANED') EXECUTE PROCEDURE receive_exemplar();
