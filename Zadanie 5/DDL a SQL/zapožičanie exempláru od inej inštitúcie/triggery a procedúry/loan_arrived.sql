CREATE OR REPLACE FUNCTION loan_arrived(exemplar_name TEXT) RETURNS VOID AS $$
BEGIN
    UPDATE exemplars 
    SET ownership_status = 'LOANED', current_status = 'IN_STORAGE' 
    WHERE name = exemplar_name;
END;
$$ LANGUAGE plpgsql;