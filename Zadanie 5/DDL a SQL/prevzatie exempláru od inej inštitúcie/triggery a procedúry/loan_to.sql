-- Požičanie exempláru inštitúcii
CREATE OR REPLACE FUNCTION loan_to(exemplar_name TEXT, institution_name TEXT, start_date TIMESTAMP, end_date TIMESTAMP, available TIMESTAMP) RETURNS VOID AS $$
DECLARE own_status ownership_status_enum;
BEGIN
	SELECT ownership_status INTO own_status FROM exemplars WHERE name = exemplar_name;
	IF own_status <> 'OWNED' THEN
		RAISE EXCEPTION 'Nie je možné zapožičať nevlastnený alebo momentálne zapožičaný exemplár.';
	END IF;
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