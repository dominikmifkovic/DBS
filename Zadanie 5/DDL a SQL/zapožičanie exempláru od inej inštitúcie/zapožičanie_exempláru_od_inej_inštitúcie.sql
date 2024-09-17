-- Vytvorenie zapožičania
SELECT loan_from(
    'Socha'::text, 
    'ZAPOZICANE'::text, 
    'Popis'::text,  
    'Inštitúcia 1'::text,  
    NOW()::timestamp, 
    NOW()::timestamp + INTERVAL '5 days', 
    NOW()::timestamp  
);

-- Exemplár dorazil
SELECT loan_arrived('ZAPOZICANE'::text);
