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

-----------------------------------------------------------------------------

-- fraud_rate by product category

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
------------------------------------------------------------------
		







