-- ==========================================================
-- C&N AGENTES INMOBILIARIOS
-- Datos de prueba - PostgreSQL
-- Ejecutar después de database/schema.sql y database/functions.sql.
-- Los registros generados son ficticios.
-- ==========================================================

SET search_path TO public;

-- 1. Tipos de documento
INSERT INTO DOCUMENT_TYPE (ID, NAME) VALUES
('CC',  'Cédula de ciudadanía'),
('CE',  'Cédula de extranjería'),
('PAS', 'Pasaporte'),
('NIT', 'NIT');

-- 2. Barrios
INSERT INTO NEIGHBORHOOD (ID, NAME)
SELECT 'B' || LPAD(n::text, 2, '0'),
       (ARRAY['Centro','La Playa','El Carmen','San Agustín','Los Almendros',
              'La Esperanza','Villa del Río','El Bosque','San José','Las Palmas',
              'Santa Ana','El Poblado','La Floresta','Altos del Prado','Villa Nueva',
              'El Refugio','Los Pinos','San Antonio','La Colina','Brisas del Norte'])[n]
FROM generate_series(1, 20) AS n;

-- 3. Asesores comerciales
INSERT INTO SALES_CONSULTANT (
    ID, FIRST_NAME, MIDDLE_NAME, FIRST_SURNAME,
    SECOND_SURNAME, PHONE, EMAIL
)
SELECT 'S' || LPAD(n::text, 3, '0'),
       (ARRAY['Carlos','María','Andrés','Laura','Juan','Paola','Diego','Camila','Felipe','Valentina'])[1 + (n % 10)],
       (ARRAY['Alberto','Fernanda','David','Sofía','Camilo','Andrea','Esteban','Lucía','Mateo','Isabel'])[1 + ((n * 3) % 10)],
       (ARRAY['Gómez','Rodríguez','Martínez','López','García','Pérez','Sánchez','Ramírez','Torres','Díaz'])[1 + ((n * 7) % 10)],
       (ARRAY['Castro','Vargas','Rojas','Moreno','Jiménez','Ortiz','Herrera','Mendoza','Silva','Cruz'])[1 + ((n * 11) % 10)],
       '3' || LPAD((100000000 + n * 7919)::text, 9, '0'),
       'asesor' || n || '@inmobiliaria.com'
FROM generate_series(1, 20) AS n;

-- 4. Clientes
INSERT INTO CUSTOMER (
    ID, DOCUMENT_TYPE_ID, DOCUMENT_NUMBER, FIRST_NAME, MIDDLE_NAME,
    FIRST_SURNAME, SECOND_SURNAME, PHONE, EMAIL, BUDGET
)
SELECT 'C' || LPAD(n::text, 5, '0'),
       (ARRAY['CC','CC','CC','CE','PAS','NIT'])[1 + (n % 6)],
       (10000000 + n * 997)::text,
       (ARRAY['Juan','Ana','Luis','Marta','Pedro','Sara','Jorge','Elena','Ricardo','Natalia'])[1 + (n % 10)],
       (ARRAY['José','Carolina','Antonio','Patricia','Javier','Marcela','Alejandro','Daniela','Sebastián','Viviana'])[1 + ((n * 3) % 10)],
       (ARRAY['Hernández','Gutiérrez','Ruiz','Navarro','Salazar','Peña','Quintero','Cortés','Arias','Ríos'])[1 + ((n * 7) % 10)],
       (ARRAY['Molina','Suárez','Ospina','Cardona','Valencia','Bedoya','Montoya','Parra','Villa','Cano'])[1 + ((n * 11) % 10)],
       '3' || LPAD((200000000 + n * 6007)::text, 9, '0'),
       'cliente' || n || '@correo.com',
       ROUND((50000000 + random() * 450000000)::numeric, 0)
FROM generate_series(1, 1000) AS n;

-- 5. Propiedades
-- Todas comienzan DISPONIBLE para que los triggers puedan validar
-- la creación de contratos y actualizar posteriormente su estado.
INSERT INTO PROPERTY (
    ID, NEIGHBORHOOD_ID, ADDRESS, OPERATION_TYPE, AREA, ROOMS,
    BATHROOMS, STATUS, SALE_PRICE, RENTAL_RATE
)
SELECT 'P' || LPAD(n::text, 5, '0'),
       'B' || LPAD((((n - 1) % 20) + 1)::text, 2, '0'),
       'Calle ' || (1 + (n % 80)) || ' # ' || (1 + (n % 50)) || '-' || (1 + (n % 99)),
       CASE WHEN n <= 1000 THEN 'ARRIENDO' ELSE 'VENTA' END,
       ROUND((30 + random() * 220)::numeric, 2),
       1 + (n % 5),
       1 + (n % 3),
       'DISPONIBLE',
       CASE WHEN n > 1000 THEN ROUND((80000000 + random() * 820000000)::numeric, 0) END,
       CASE WHEN n <= 1000 THEN ROUND((500000 + random() * 4500000)::numeric, 0) END
FROM generate_series(1, 2000) AS n;

-- 6. Contratos de arrendamiento
INSERT INTO CONTRACT_RENTAL (
    CUSTOMER_ID, CUSTOMER_DOCUMENT_TYPE_ID, PROPERTY_ID,
    PROPERTY_NEIGHBORHOOD_ID, SALES_CONSULTANT_ID,
    START_DATE, DURATION, RENTAL_VALUE, DEPOSIT_VALUE
)
SELECT c.ID, c.DOCUMENT_TYPE_ID, p.ID, p.NEIGHBORHOOD_ID,
       'S' || LPAD((((c.rn - 1) % 20) + 1)::text, 3, '0'),
       DATE '2023-01-01' + (random() * 1000)::int,
       (ARRAY[6, 12, 12, 18, 24, 36])[1 + (c.rn % 6)],
       p.RENTAL_RATE,
       p.RENTAL_RATE * (1 + (c.rn % 2))
FROM (SELECT *, ROW_NUMBER() OVER (ORDER BY ID) AS rn FROM CUSTOMER) c
JOIN (
    SELECT *, ROW_NUMBER() OVER (ORDER BY ID) AS rn
    FROM PROPERTY
    WHERE OPERATION_TYPE = 'ARRIENDO'
) p ON p.rn = c.rn;

-- 7. Contratos de compraventa
INSERT INTO CONTRACT_SALE (
    PROPERTY_ID, PROPERTY_NEIGHBORHOOD_ID, CUSTOMER_ID,
    CUSTOMER_DOCUMENT_TYPE_ID, SALES_CONSULTANT_ID,
    SALE_DATE, AGREED_VALUE, DEED_DATE
)
SELECT p.ID, p.NEIGHBORHOOD_ID, c.ID, c.DOCUMENT_TYPE_ID,
       'S' || LPAD((((p.rn - 1) % 20) + 1)::text, 3, '0'),
       s.sale_date,
       ROUND((p.SALE_PRICE * (0.90 + random() * 0.10))::numeric, 0),
       s.sale_date + (15 + (random() * 45)::int)
FROM (
    SELECT *, ROW_NUMBER() OVER (ORDER BY ID) AS rn
    FROM PROPERTY
    WHERE OPERATION_TYPE = 'VENTA'
) p
JOIN (
    SELECT *, ROW_NUMBER() OVER (ORDER BY ID) AS rn
    FROM CUSTOMER
) c ON c.rn = ((p.rn + 499) % 1000) + 1
CROSS JOIN LATERAL (
    SELECT DATE '2022-01-01' + (random() * 1400)::int AS sale_date
) s;

-- 8. Cláusulas de contratos de arrendamiento
INSERT INTO CLAUSE (
    ID, DESCRIPTION, CONTRACT_RENTAL_CUSTOMER_ID,
    CONTRACT_RENTAL_DOCUMENT_TYPE_ID, CONTRACT_RENTAL_PROPERTY_ID,
    CONTRACT_RENTAL_PROPERTY_NEIGHBORHOOD_ID
)
SELECT 'CLR' || LPAD((ROW_NUMBER() OVER ())::text, 5, '0'),
       (ARRAY[
           'El arrendatario debe pagar el canon dentro de los primeros 5 días de cada mes',
           'El inmueble solo podrá usarse como vivienda',
           'Prohibido subarrendar sin autorización escrita del propietario',
           'El depósito será devuelto al finalizar el contrato previa revisión del inmueble',
           'El incremento anual del canon será igual al IPC'
       ])[1 + ((ROW_NUMBER() OVER ())::int % 5)],
       CUSTOMER_ID, CUSTOMER_DOCUMENT_TYPE_ID, PROPERTY_ID,
       PROPERTY_NEIGHBORHOOD_ID
FROM CONTRACT_RENTAL;

-- 9. Cláusulas de contratos de compraventa
INSERT INTO CLAUSE (
    ID, DESCRIPTION, CONTRACT_SALE_PROPERTY_ID,
    CONTRACT_SALE_NEIGHBORHOOD_ID, CONTRACT_SALE_CUSTOMER_ID,
    CONTRACT_SALE_DOCUMENT_TYPE_ID
)
SELECT 'CLV' || LPAD((ROW_NUMBER() OVER ())::text, 5, '0'),
       (ARRAY[
           'El vendedor entrega el inmueble libre de gravámenes y embargos',
           'El comprador asume los gastos de escrituración y registro',
           'La entrega material se hará en la fecha de firma de la escritura',
           'El inmueble se vende como cuerpo cierto',
           'El incumplimiento genera una cláusula penal del 10% del valor pactado'
       ])[1 + ((ROW_NUMBER() OVER ())::int % 5)],
       PROPERTY_ID, PROPERTY_NEIGHBORHOOD_ID, CUSTOMER_ID,
       CUSTOMER_DOCUMENT_TYPE_ID
FROM CONTRACT_SALE;
