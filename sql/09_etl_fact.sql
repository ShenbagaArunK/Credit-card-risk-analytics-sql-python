-- Insert data into facts table

insert into fraud_dw.fact_transactions(
	transaction_id,
    transaction_dt,
    date_id,
    card_id,
    product_id,
    device_id,
    geography_id,
    purchase_email_id,
    recipient_email_id,
    transaction_amt,
    is_fraud,
    hour_of_day,
    dist_billing_shipping
)
select 
	t.transaction_id,
	
	-- timestamp from start date 2017-12-01
	'2017-12-01'::timestamp + t.transaction_dt * interval '1 second' as transaction_dt,
	
	-- Date_id derived frm the timestamp
	to_char(('2017-12-01'::timestamp + t.transaction_dt * interval '1 second')::Date,'YYYYMMDD')::Integer as date_id,
	
	-- card_id : direct lookup
	dc.card_id,
	
	-- product_id : lookup
	dp.product_id,
	
	-- device_id - lookup with fallback
	coalesce(dd.device_id,dd_unknown.device_id) as device_id,

	-- geography_id
	dg.geography_id,

	-- purchaser email
	de_p.email_domain_id as purchase_email_id,

	-- recipient email
	de_r.email_domain_id as recipient_email_id,

	-- measures
	t.transaction_amt,

	-- converting 0/1 -- boolean
	(t.is_fraud=1) as is_fraud,

	-- Hour of day
	extract(hour from ('2017-12-01'::timestamp + t.transaction_dt * interval '1 second'))::smallint as hour_of_day,

	-- distance 
	t.dist1 as dist_billing_shipping

	
from staging.pros_transaction t
left join staging.pros_identity i
on i.transaction_id = t.transaction_id

-- dim_card
left join fraud_dw.dim_card dc
	on coalesce(dc.card1,-1) = coalesce(t.card1,-1)
	AND COALESCE(dc.card2, -1) = COALESCE(t.card2, -1)
    AND COALESCE(dc.card3, -1) = COALESCE(t.card3, -1)
    AND COALESCE(dc.card4, '') = COALESCE(t.card4, '')
    AND COALESCE(dc.card5, -1) = COALESCE(t.card5, -1)
    AND COALESCE(dc.card6, '') = COALESCE(t.card6, '')

-- dim_product
left join fraud_dw.dim_product dp
	on dp.product_cd = t.product_cd

-- dim_device
left join fraud_dw.dim_device dd
	on dd.device_type = coalesce(lower(trim(i.device_type)), 'unknown')
	and coalesce(dd.device_info, '') = coalesce(nullif(trim(i.device_info),''),'')
	and dd.operating_system = coalesce(lower(trim(i.id_30)),'unknown')
	and dd.browser			= coalesce(lower(trim(i.id_31)),'unknown')
	and dd.screen_resolution= coalesce(trim(i.id_33),'unknown')

-- setting up fallback to unknown column
-- using cross join so in select we can give fallback device_id
cross join(
select device_id
from fraud_dw.dim_device
where device_type = 'unknown'
	and device_info is null
limit 1
) dd_unknown

-- dim_geography
left join fraud_dw.dim_geography dg
	on coalesce(dg.addr1,-1) = coalesce(t.addr1, -1)
	and coalesce(dg.addr2,-1) = coalesce(t.addr2, -1)

-- dim email_domain -- split to purchaser and recipient

-- Purschase email
left join fraud_dw.dim_email_domain de_p
	on de_p.email_domain = coalesce(lower(trim(t.p_emaildomain)), 'unknown')

-- Recipient email
left join fraud_dw.dim_email_domain de_r
	on de_r.email_domain = coalesce(lower(trim(t.r_emaildomain)), 'unknown')

----------------------------------------------------------------------------------
-- verifying

-- row counts
select 
	(select count(*) from staging.pros_transaction) as staging_count,
	(select count(*) from fraud_dw.fact_transactions) as fact_count,
	(select count(*) from staging.pros_transaction) - (select count(*) from fraud_dw.fact_transactions) as differnece
	
-- difference is 0

--------------------------------------
-- Fraud_rate
select is_fraud,
		count(*) as cnt,
		round(100 * count(*)/sum(count(*)) over (),2) as pct
from fraud_dw.fact_transactions
group by is_fraud
order by is_fraud desc;

-----------------------------------------------
-- chking null ids
select 
		count(*) filter (where date_id is null) as null_date_id,
		count(*) filter (where device_id is null) as null_device_id,
		count(*) filter (where card_id is null) as null_card_id
		from fraud_dw.fact_transactions;

--  all are 0 
-----------------------------------------------

-- date range match

select min(transaction_dt) as earliest_date,
		max(transaction_dt) as latest_date
from 	fraud_dw.fact_transactions;

---------------------------------------------
-- chking fk reference integrity
select count(*) as mismatch_card_ids
from fraud_dw.fact_transactions f
left join fraud_dw.dim_card dc
on		f.card_id = dc.card_id
where dc.card_id is null;
-- returned 0
----------------------------------------------
-- Chk coverage matches the expected 
select device_type,
		count(*) as cnt,
		round(100* count(*)/sum(count(*)) over (),2) as pct
from 	fraud_dw.fact_transactions f
left join 	fraud_dw.dim_device dd
on 			f.device_id = dd.device_id
group by dd.device_type
order by cnt desc;
-- unknown - 76,desktop - 14,mobile - 10
-----------------------------------------------------
-- fraud_rate by card network
select card_network,
		count(*) as tot_cnt,
		count(*) filter (where is_fraud is True) as fraud_cnt,
		round(100* count(*) filter (where is_fraud is True)/count(*),2) as fraud_rate_pct
from 	fraud_dw.fact_transactions f
left join 	fraud_dw.dim_card dc
on 			f.card_id = dc.card_id
group by dc.card_network
order by fraud_rate_pct desc;
-----------------------------------------------------
-- Fraud rate by hour of day (preview of Phase 2)
SELECT 
    hour_of_day,
    COUNT(*)                                           AS txn_count,
    COUNT(*) FILTER (WHERE is_fraud)                   AS fraud_count,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_fraud) / COUNT(*), 2) AS fraud_rate_pct
FROM fraud_dw.fact_transactions
GROUP BY hour_of_day
ORDER BY hour_of_day;
-------------------------------------------------
-- Fraud rate by product category
SELECT 
    p.product_category,
    COUNT(*)                                           AS txn_count,
    COUNT(*) FILTER (WHERE f.is_fraud)                 AS fraud_count,
    ROUND(100.0 * COUNT(*) FILTER (WHERE f.is_fraud) / COUNT(*), 2) AS fraud_rate_pct
FROM fraud_dw.fact_transactions f
JOIN fraud_dw.dim_product p ON f.product_id = p.product_id
GROUP BY p.product_category
ORDER BY fraud_rate_pct DESC;
-------------------------------------------------
-- Optional if wanted we can drop the staging schema nd tables 

-- Optional cleanup
DROP TABLE staging.stg_transaction;
DROP TABLE staging.stg_identity;
DROP SCHEMA staging;
---------------------------------------------------


