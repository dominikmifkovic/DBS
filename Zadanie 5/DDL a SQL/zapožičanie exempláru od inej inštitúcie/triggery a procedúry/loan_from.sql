CREATE OR REPLACE FUNCTION loan_from(
    in_category_name TEXT,
    in_exemplar_name TEXT,
    in_description TEXT,
    in_involved_institution_name TEXT,
    in_loan_start_date TIMESTAMP,
    in_loan_end_date TIMESTAMP,
    in_expected_availability TIMESTAMP
) RETURNS VOID AS $$
DECLARE
    v_category_id INTEGER;
    v_involved_institution_id INTEGER;
    v_exemplar_id INTEGER;
BEGIN
    -- Vloženie nového exemplára
    INSERT INTO exemplars (category_id, name, description, ownership_status, current_status)
    VALUES ((SELECT id FROM categories WHERE name = in_category_name), 
            in_exemplar_name, 
            in_description, 
            'LOANED', 
            'IN_TRANSIT');

    -- Získanie ID vloženého exemplára
    SELECT id INTO v_exemplar_id FROM exemplars WHERE name = in_exemplar_name;

    -- Vloženie nového záznamu o pôžičke
    INSERT INTO loans (exemplar_id, type, involved_institution_id, loan_start_date, loan_end_date, expected_exemplar_availability)
    VALUES (v_exemplar_id,
            'LOANED_IN',
            (SELECT id FROM institutions WHERE name = in_involved_institution_name),
            in_loan_start_date,
            in_loan_end_date,
            in_expected_availability);
END;
$$ LANGUAGE plpgsql;