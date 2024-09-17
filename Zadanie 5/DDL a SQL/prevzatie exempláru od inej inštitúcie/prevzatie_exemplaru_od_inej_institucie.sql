-- Vytvorenie exempláru na požičanie
INSERT INTO exemplars (category_id, name, description, ownership_status, current_status)
VALUES ((SELECT id FROM categories WHERE name = 'Socha'), 'POZICANIE', 'Popis', 'OWNED', 'IN_STORAGE');

-- Požičanie exempláru
SELECT loan_to('POZICANIE'::text, 'Inštitúcia 1'::text, NOW()::TIMESTAMP, NOW()::TIMESTAMP + INTERVAL '5 days' , NOW()::TIMESTAMP + INTERVAL '5 days');

-- Prevzatie exempláru
SELECT loan_to_returned('POZICANIE'::text);

-- Manuálne ukončenie inšpekcie
SELECT end_inspection('POZICANIE'::text);
