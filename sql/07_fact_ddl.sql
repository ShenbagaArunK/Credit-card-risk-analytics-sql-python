-- Fact table transactions

drop table if exists fraud_dw.fact_transactions cascade;

create table fraud_dw.fact_transactions(

transaction_id	bigint primary key,
transaction_dt	timestamp not null,

date_id 	integer not null references fraud_dw.dim_date(date_id),
card_id		integer not null references fraud_dw.dim_card(card_id),
product_id	integer not null references fraud_dw.dim_product(product_id),
device_id	integer not null references fraud_dw.dim_device(device_id),
geography_id integer not null references fraud_dw.dim_geography(geography_id),
purchase_email_id integer not null references fraud_dw.dim_email_domain(email_domain_id),
recipient_email_id integer not null references fraud_dw.dim_email_domain(email_domain_id),

transaction_amt		numeric(12,2) not null,
is_fraud			boolean not null,
hour_of_day			smallint not null,
dist_billing_shipping	numeric
);

----------------------------------
-- indexing 

create index idx_fraud_date
on fraud_dw.fact_transactions(date_id);

create index idx_fact_dt_hour
on fraud_dw.fact_transactions(transaction_dt,hour_of_day);

create index idx_fact_card_dt
on fraud_dw.fact_transactions(card_id,transaction_dt);

create index idx_fact_fraud
on fraud_dw.fact_transactions(is_fraud)
where is_fraud = True;

create index idx_fact_amt
on fraud_dw.fact_transactions(transaction_amt);

create index idx_fact_device
on fraud_dw.fact_transactions(device_id);

-----------------------------------------------

-- Checks

-- All tables in fraud_dw with their column counts
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns 
     WHERE table_schema = 'fraud_dw' AND table_name = t.table_name) AS columns
FROM information_schema.tables t
WHERE table_schema = 'fraud_dw'
ORDER BY 
    CASE WHEN table_name = 'fact_transactions' THEN 2 ELSE 1 END,
    table_name;




-- All foreign key relationships
SELECT
    tc.table_name AS table_name,
    kcu.column_name AS column_name,
    ccu.table_name AS references_table,
    ccu.column_name AS references_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu 
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'fraud_dw'
ORDER BY tc.table_name, kcu.column_name;



-- All indexes on fact_transactions
SELECT indexname FROM pg_indexes 
WHERE schemaname = 'fraud_dw' AND tablename = 'fact_transactions'
ORDER BY indexname;
