-- Manuálne ukončenie kontroly pre ukážku 
CREATE OR REPLACE FUNCTION end_inspection(exemplar_name TEXT) RETURNS VOID AS $$
BEGIN
    UPDATE exemplars 
    SET ownership_status = 'OWNED', current_status = 'IN_STORAGE' 
    WHERE name = exemplar_name;
END;
$$ LANGUAGE plpgsql;