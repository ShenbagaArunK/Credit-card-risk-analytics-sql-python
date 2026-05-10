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
	on de_p.email_domain = lower(trim(t.p_emaildomain))

-- Recipient email
left join fraud_dw.dim_email_domain de_r
	on de_r.email_domain = lower(trim(t.r_emaildomain))






