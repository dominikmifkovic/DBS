SELECT create_exposition('PLANNED EXPO'::text, ARRAY['Maľba 1'],  ARRAY['Zóna 1'], '2025-01-01'::timestamp, '2025-01-02'::timestamp);
SELECT create_exposition('IN PROGRESS EXPO'::text, ARRAY['Fotografia 1'],  ARRAY['Zóna 2'], '2023-01-01'::timestamp, '2024-10-10'::timestamp);

-- Neúspešné pridanie ďalšej zóny do expozície 'IN PROGRESS EXPO' (zóna obsadená)
DO $$
DECLARE
    expo_id INTEGER;
BEGIN
SELECT id INTO expo_id FROM expositions WHERE name = 'IN PROGRESS EXPO';
INSERT INTO exposition_zones (exposition_id, zone_id)
    VALUES (expo_id, (SELECT id FROM zones WHERE name = 'Zóna 2'));
END $$;

-- Úspešné pridanie ďalšej zóny do expozície 'IN PROGRESS EXPO'
DO $$
DECLARE
    expo_id INTEGER;
BEGIN
SELECT id INTO expo_id FROM expositions WHERE name = 'IN PROGRESS EXPO';
INSERT INTO exposition_zones (exposition_id, zone_id)
    VALUES (expo_id, (SELECT id FROM zones WHERE name = 'Zóna 3'));
END $$;


-- Úspešné presunutie
UPDATE exemplars_zones SET zone_id = 3 WHERE exemplar_id IN (SELECT id FROM exemplars WHERE name = 'Fotografia 1');


-- Neúspešné presunutie, zóna nepatrí expozícii v ktorej exemplár je
UPDATE exemplars_zones SET zone_id = 3 WHERE exemplar_id IN (SELECT id FROM exemplars WHERE name = 'Maľba 1');