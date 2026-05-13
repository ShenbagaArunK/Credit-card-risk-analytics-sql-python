-- Phase 1 Analytical Queries 

-- Here we will do in deapth fraud analysis with important features

-- 01. Overall fraud_rate by count and by transactional amount

select 
		count(*) 												as tot_transactions,
		count(*) filter (where is_fraud is true)				as fraud_transactions,
		round(100 * count(*) filter (where is_fraud)
						/count(*),2)							as fraud_rate_count_pct,

		round(sum(transaction_amt),2)							as total_amount,
		round(sum(transaction_amt) filter(where is_fraud),2)	as fraud_amount,
		round(100 * sum(transaction_amt) filter(where is_fraud)
				/ sum(transaction_amt),2)						as fraud_rate_amount_pct
from fraud_dw.fact_transactions;

-- findings -- 


-----------------------------------------------------------------------------

-- 02.fraud_rate by product category

select 
		p.product_category,
		count(*) 										as txn_count,
		count(*) filter (where f.is_fraud)				as fraud_count,
		round(100 * count(*) filter (where f.is_fraud)	
						/count(*),2)					as fraud_rate_pct,
						
		round(sum(f.transaction_amt),2)							as total_amount,
		round(sum(f.transaction_amt) filter(where is_fraud),2)	as fraud_amount
from fraud_dw.fact_transactions f
left join fraud_dw.dim_product p
on f.product_id = p.product_id
group by p.product_category
order by fraud_rate_pct desc;

-- findings -- 


------------------------------------------------------------------

-- 03.fraud_rate by card_network

select 
		c.card_network,		
		count(*) 										as txn_count,
		count(*) filter (where f.is_fraud)				as fraud_count,
		round(100 * count(*) filter (where f.is_fraud)	
						/count(*),2)					as fraud_rate_pct,
		round(avg(transaction_amt),2)					as avg_txn_amt,
		round(avg(transaction_amt) filter 
				(where is_fraud),2)						as avg_fraud_amt
from fraud_dw.fact_transactions f
join fraud_dw.dim_card c using (card_id)
group by c.card_network
order by txn_count desc;

-- findings -- 

---------------------------------------------------------------------

-- 04.fraud rate by card type

select 
		c.card_type,		
		count(*) 										as txn_count,
		count(*) filter (where f.is_fraud)				as fraud_count,
		round(100 * count(*) filter (where f.is_fraud)	
						/count(*),2)					as fraud_rate_pct,
		round(avg(transaction_amt),2)					as avg_txn_amt,
		round(avg(transaction_amt) filter 
				(where is_fraud),2)						as avg_fraud_amt
from fraud_dw.fact_transactions f
join fraud_dw.dim_card c using (card_id)
group by c.card_type
order by txn_count desc;

-- findings -- 

--------------------------------------------------------------------------

-- 05.Statistical distribution between Legit nd fraud transaction
-- Finding Quantiles,min, max,mean, modian

select
		is_fraud,
		count(*) 										as txn_count,
		round(min(transaction_amt),2)					as min_amt,
		round(percentile_cont(0.25) within group
				(order by transaction_amt)::numeric,2)	as p25,
		round(percentile_cont(0.50) within group
				(order by transaction_amt)::numeric,2)	as median,
		round(avg(transaction_amt),2)					as mean,
		round(percentile_cont(0.75) within group
				(order by transaction_amt)::numeric,2)	as p75,
		round(percentile_cont(0.95) within group
				(order by transaction_amt)::numeric,2)	as p95,
		round(max(transaction_amt),2)					as max_amt
from 	fraud_dw.fact_transactions
group by is_fraud
order by is_fraud;

-- findings -- 

--------------------------------------------------------------------------		
-- 06. checking multiple aggregation levels of feaud_rate

select
		coalesce(p.product_category,'All Products')					as product_category,
		coalesce(c.card_type,'All types')							as card_type,
		count(*)													as txn_count,
		count(*) filter (where is_fraud)							as fraud_count,
		round(100 * count(*) filter (where is_fraud)
					/ count(*),2)									as fraud_pct
from fraud_dw.fact_transactions f
join fraud_dw.dim_product p using (product_id)
join fraud_dw.dim_card c using (card_id)
group by grouping sets (
    (p.product_category, c.card_type),     -- detail level
    (p.product_category),                  -- by product only
    (c.card_type),                         -- by card type only
    ()                                     -- grand total
)

order by CASE WHEN p.product_category IS NULL THEN 2 ELSE 1 END,
					p.product_category,
					CASE WHEN c.card_type IS NULL THEN 2 ELSE 1 END,
					c.card_type;


-- findings -- 

--------------------------------------------------------------------------		











