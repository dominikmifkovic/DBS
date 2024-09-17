-- Prevzatie požičaného exempláru od inštitúcie
CREATE OR REPLACE FUNCTION loan_to_returned(exemplar_name TEXT) RETURNS VOID AS $$
BEGIN
    UPDATE exemplars 
    SET ownership_status = 'OWNED', current_status = 'BEING_INSPECTED' 
    WHERE name = exemplar_name;
END;
$$ LANGUAGE plpgsql;
