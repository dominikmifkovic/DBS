INSERT INTO exemplars (category_id, name, description, ownership_status, current_status)
VALUES ((SELECT id FROM categories WHERE name = 'MENO KATEGORIE'), 'MENO EXEMPLARU', 'POPIS EXEMPLARU', 'OWNED', 'IN_STORAGE');