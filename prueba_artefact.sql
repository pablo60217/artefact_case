/*CREATE VIEW db_transac AS 
SELECT * FROM read_csv_auto('/Users/pablocamacho/Library/Mobile Documents/com~apple~CloudDocs/Aplicaciones/Artefact/Analytics Engineer/db/db_transac (1).csv');
*/
/*CREATE VIEW mcg AS
SELECT * FROM read_csv_auto('/Users/pablocamacho/Library/Mobile Documents/com~apple~CloudDocs/Aplicaciones/Artefact/Analytics Engineer/db/mcg_list.csv')
*/

/*CREATE VIEW transactions_cleaned AS
SELECT * FROM read_csv_auto('/Users/pablocamacho/Library/Mobile Documents/com~apple~CloudDocs/Aplicaciones/Artefact/Analytics Engineer/db/transactions_cleaned.csv')
*/

/*Volumen: Cantidad de tarjetas por tipo, que han realizado
transacciones en cada trimestre*/


SELECT
    CASE 
        WHEN product_type IN ('Debit', 'Debito', 'Débito') THEN 'Debito'
        WHEN product_type IN ('Crédito', 'Credito', 'Credit') THEN 'Credito'
        ELSE 'NA'
    END AS product_type_clean,
    CONCAT('Q', QUARTER(prch_datetime), '-', YEAR(prch_datetime)) AS trimester_year,
    COUNT(DISTINCT card_id) AS total_cards
FROM transactions_cleaned
GROUP BY product_type_clean, CONCAT('Q', QUARTER(prch_datetime), '-', YEAR(prch_datetime))

/*Ticket Trimestral: Gasto promedio por tarjeta de crédito por
trimestre.*/

SELECT
    CASE 
        WHEN product_type IN ('Debit', 'Debito', 'Débito') THEN 'Debito'
        WHEN product_type IN ('Crédito', 'Credito', 'Credit') THEN 'Credito'
        ELSE 'NA'
    END AS product_type_clean,
    CONCAT('Q', QUARTER(prch_datetime), '-', YEAR(prch_datetime)) AS trimester_year,
    COUNT(DISTINCT card_id) AS total_cards,
    SUM(amt) as spent,
    (SUM(amt))/(COUNT(DISTINCT card_id)) as avg_spent_per_card
FROM transactions_cleaned
GROUP BY product_type_clean, CONCAT('Q', QUARTER(prch_datetime), '-', YEAR(prch_datetime))



/*Ticket Regional: Monto de transacción promedio de tarjetas de
crédito por producto en países de Sudamérica.*/

SELECT
	ctry_mrch,
	AVG(amt) as avg_spent_per_product
FROM transactions_cleaned
GROUP BY ctry_mrch 
ORDER BY 2 DESC



/*Top Comercios: Ranking Top 10 de porcentaje de gasto por nombre
de MCG (Merchant Category Group).*/

WITH base AS (
    SELECT
        m.mcg,
        m.mcg_name,
        SUM(amt) AS spent,
        SUM(SUM(amt)) OVER () AS total_spent,
        ROUND(SUM(amt) / SUM(SUM(amt)) OVER () * 100, 2) AS pct_of_total
    FROM mcg AS m
    LEFT JOIN transactions_cleaned AS tc
        ON m.mcg = tc.mcg_id
    GROUP BY m.mcg, m.mcg_name
),
ranked AS (
    SELECT *,
        DENSE_RANK() OVER (ORDER BY pct_of_total DESC) AS rank
    FROM base
)
SELECT mcg, mcg_name, spent, total_spent, pct_of_total, rank
FROM ranked
WHERE rank <= 10
ORDER BY rank

/*Adopción Tecnológica: Porcentaje de gasto contactless ordenado
por país.*/


SELECT ctry_card, AVG(is_contactless) as por_gasto_contactless
FROM transactions_cleaned
GROUP BY ctry_card
ORDER BY por_gasto_contactless

/* transacciones de tarjetas chilenas en paises extranjeros da 7% de cashback, max 50 USD de 
 cashbackctry_card */

with base as (SELECT 
	card_id,
	ctry_card, 
	ctry_mrch, 
	CASE WHEN
		ctry_card <> ctry_mrch
		THEN 1
		ELSE 0
		END AS compra_exterior,
	sum(amt) as spent
FROM transactions_cleaned
WHERE amt > 0
AND (date (prch_date) BETWEEN '2024-05-01' AND '2024-05-31')
AND ctry_card == 'Chile'
and compra_exterior = 1
GROUP BY card_id, ctry_card, ctry_mrch),

cashback as (SELECT 
	card_id, 
	sum(spent),
	CASE WHEN sum(spent) >= (50 / 0.07)
	THEN 50
	else sum(spent) * .07
	END AS cashback_value
FROM base
GROUP BY card_id)


/* costo campana*/
/*
SELECT sum(cashback_value)
FROM cashback*/

/*Tarjetas impactadas*/

SELECT COUNT(DISTINCT card_id)
FROM cashback
