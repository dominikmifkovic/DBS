CREATE OR REPLACE FUNCTION create_exposition(exp_name TEXT, exemplare TEXT[], zony TEXT[], start_date TIMESTAMP, end_date TIMESTAMP) RETURNS VOID AS $$
DECLARE
    expo_id INTEGER;
    exemplar_name TEXT;
    zone_name TEXT;
BEGIN
    -- Vytvorenie novej expozície
    INSERT INTO expositions (name, start_date, end_date)
    VALUES (exp_name, start_date, end_date);

    -- Získanie ID novej expozície
    SELECT id INTO expo_id FROM expositions WHERE name = exp_name;

    -- Pridanie exemplárov do expozície
    FOR i IN 1..array_length(exemplare, 1) LOOP
        exemplar_name := exemplare[i];
        INSERT INTO exemplar_expositions (exemplar_id, exposition_id)
        VALUES ((SELECT id FROM exemplars WHERE name = exemplar_name), expo_id);
    END LOOP;

    -- Obsadenie zón
    FOR j IN 1..array_length(zony, 1) LOOP
        zone_name := zony[j];
        INSERT INTO exposition_zones (exposition_id, zone_id)
        VALUES (expo_id, (SELECT id FROM zones WHERE name = zone_name));
    END LOOP;
END;
$$ LANGUAGE plpgsql;