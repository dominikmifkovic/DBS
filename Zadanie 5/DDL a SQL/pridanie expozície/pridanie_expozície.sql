SELECT create_exposition('PLANNED EXPO'::text, ARRAY['Maľba 1'],  ARRAY['Zóna 1'], '2025-01-01'::timestamp, '2025-01-02'::timestamp);
SELECT create_exposition('IN PROGRESS EXPO'::text, ARRAY['Fotografia 1'],  ARRAY['Zóna 2'], '2023-01-01'::timestamp, '2024-10-10'::timestamp);

DO $$
DECLARE
    expo_id INTEGER;
BEGIN
SELECT id INTO expo_id FROM expositions WHERE name = 'IN PROGRESS EXPO';
INSERT INTO exposition_zones (exposition_id, zone_id)
    VALUES (expo_id, (SELECT id FROM zones WHERE name = 'Zóna 3'));
END $$;

SELECT * FROM expositions;

-- Aktualizovanie dátumu expozícíí
UPDATE expositions SET start_date = '2024-01-01' WHERE name = 'PLANNED EXPO';
UPDATE expositions SET end_date = '2024-03-01' WHERE name = 'IN PROGRESS EXPO';
