-- Phase 04 -- Combination of Variables predicting fraud ?

-- Q1. Fraud rate by amount quintile

with amt_buckets as(
	select 		
			transaction_id,
			is_fraud,
			transaction_amt,
			ntile(5) over (order by transaction_amt) as amt_quintile
	from fraud_dw.fact_transactions
)

select 
		amt_quintile,
		count(*) 						as txn_count,
		round(min(transaction_amt),2) 	as min_amt,
		round(max(transaction_amt),2)	as max_amt,
		count(*) filter(where is_fraud)	as fraud_count,
		round(100 * count(*)
			filter (where is_fraud)/count(*),2)		as fraud_rate_pct
from amt_buckets
group by amt_quintile
order by amt_quintile;
-------------------------------------------------------------------------------

-- Q2.Fraud rate by puschased email domain
-- Baseline fraud rate - 3.5%

select 	
		e.email_domain,
		e.domain_category,
		count(*) 									as txn_count,
		count(*) filter (where f.is_fraud) 			as fraud_count,
		round(100 * count(*)
			filter(where is_fraud)/count(*),2)		as fraud_rate_pct,
		round(100 * count(*) filter (where is_fraud)
				/ count(*) / 3.5,1)					as risk_multiple
from fraud_dw.fact_transactions f
join fraud_dw.dim_email_domain e
on f.purchase_email_id = e.email_domain_id
group by e.email_domain_id
order by fraud_rate_pct desc;
--------------------------------------------------------------------------------

-- Q3. Fraud rate by device type

select 
		d.device_type,
		count(*) 							as txn_count,
		count(*) filter (where f.is_fraud) 			as fraud_count,
		round(100 * count(*)
			filter(where is_fraud)/count(*),2)		as fraud_rate_pct,
		round(100 * count(*) filter (where is_fraud)
				/ count(*) / 3.5,1)					as risk_multiple
from fraud_dw.fact_transactions f
join fraud_dw.dim_device d using (device_id)
group by d.device_type
order by fraud_rate_pct desc;
----------------------------------------------------------------------------------

-- Q4. Fraud rate accross product * card type * device combination

select 
	coalesce(p.product_category,'All') 							as product_category,
	coalesce(c.card_type,'All')									as card_type,
	coalesce(d.device_type,'All')								as device_type,
	count(*)													as txn_count,
	count(*) filter (where f.is_fraud)							as fraud_count,
	round(100 * count(*) filter (where f.is_fraud)
			/ count(*),2)										as fraud_rate_pct
from fraud_dw.fact_transactions f 
join fraud_dw.dim_product p using (product_id)
join fraud_dw.dim_card c using (card_id)
join fraud_dw.dim_device d using (device_id)
group by cube(p.product_category,c.card_type,d.device_type)
having count(*) >= 500
order by fraud_rate_pct desc
limit 30;
---------------------------------------------------------------------------------------

-- Q5. Risk profiles ranked by fraud connections

with quaintiled as (
	select 
		f.is_fraud,
	    f.transaction_amt,
        p.product_category,
        c.card_type,
        d.device_type,
        e.domain_category,
		ntile(4) over (order by f.transaction_amt) as amt_quaintile

from fraud_dw.fact_transactions f 
join fraud_dw.dim_product p using (product_id)
join fraud_dw.dim_card c using (card_id)
join fraud_dw.dim_device d using (device_id)
join fraud_dw.dim_email_domain e 
        ON f.purchase_email_id = e.email_domain_id
)
select 
		product_category,
		card_type,
		domain_category,
		case
			when amt_quaintile=4 then 'High value' 
			 else 'Normal value' end as value_tier,
		 COUNT(*)                                            AS txn_count,
   		 COUNT(*) FILTER (WHERE is_fraud)                    AS fraud_count,
    	ROUND(100.0 * COUNT(*) FILTER (WHERE is_fraud) 
                / COUNT(*), 2)                          AS fraud_rate_pct,
    	ROUND(100.0 * COUNT(*) FILTER (WHERE is_fraud) 
                / COUNT(*) / 3.5, 1)                    AS risk_multiple
from quaintiled 
group by product_category, card_type, domain_category, value_tier
having count(*) >= 300
order by fraud_rate_pct desc
limit 20;
----------------------------------------------------------------------------------------------------------------------

-- Q6. Does high risk segments have more total fraud


WITH enriched AS (
    SELECT 
        f.is_fraud,
        p.product_category,
        e.domain_category
    FROM fraud_dw.fact_transactions f
    JOIN fraud_dw.dim_product p USING (product_id)
    JOIN fraud_dw.dim_email_domain e 
        ON f.purchase_email_id = e.email_domain_id
),
totals AS (
    SELECT COUNT(*) FILTER (WHERE is_fraud) AS total_fraud FROM enriched
)
SELECT 
    e.product_category,
    e.domain_category,
    COUNT(*)                                            AS txn_count,
    COUNT(*) FILTER (WHERE e.is_fraud)                  AS fraud_count,
    ROUND(100.0 * COUNT(*) FILTER (WHERE e.is_fraud) 
                / COUNT(*), 2)                          AS fraud_rate_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE e.is_fraud) 
                / t.total_fraud, 2)                     AS pct_of_all_fraud
FROM enriched e
CROSS JOIN totals t
GROUP BY e.product_category, e.domain_category, t.total_fraud
HAVING COUNT(*) FILTER (WHERE e.is_fraud) >= 50
ORDER BY fraud_count DESC
LIMIT 15;

--------------------------------------------------------------------------------







