-- This Query file will be used to find the time frames fraud happened

-- Q1. Fraud rate accross all 24 hrs

select hour_of_day,
		count(*) 							as txn_count,
		count(*) filter (where is_fraud)	as fraud_count,
		round(100 * count(*) filter (where is_fraud)
				/ count(*),2)				as frayd_rate_pct,
		round(avg(transaction_amt),2)		as avg_amount
from fraud_dw.fact_transactions
group by hour_of_day
order by hour_of_day;
--------------------------------------------------------

-- Q2. Fraud rate by day of the week
select d.day_of_week,
		d.day_name,
		count(*) 							as txn_count,
		count(*) filter (where is_fraud)	as fraud_count,
		round(100 * count(*) filter (where is_fraud)
				/ count(*),2)				as frayd_rate_pct
from fraud_dw.fact_transactions f
join fraud_dw.dim_date d using (date_id)
group by d.day_of_week, d.day_name
order by d.day_of_week;
------------------------------------------------------

-- Q3. Hour x Day fraud rate

select 
		d.day_of_week,
		d.day_name,
		f.hour_of_day,
		count(*) 							as txn_count,
		count(*) filter (where f.is_fraud)	as fraud_count,
		round(100 * count(*) filter (where is_fraud)
				/ nullif(count(*),0),2)				as fraud_rate_pct
from fraud_dw.fact_transactions f
join fraud_dw.dim_date d using (date_id)
group by d.day_of_week, d.day_name, f.hour_of_day
order by d.day_of_week, f.hour_of_day;
---------------------------------------------------------

-- Q4. Fraud rate week - over - week
select
		date_trunc('week',f.transaction_dt)::Date	 			as week_start,
		count(*) 												as txn_count,
		count(*) filter (where f.is_fraud) 						as fraud_count,
		round(100 * count(*) filter (where f.is_fraud)
					/ count(*),2)								as fraud_rate_pct,
		round(sum(f.transaction_amt) filter 
					(where f.is_fraud),2)						as fraud_loss_usd
from fraud_dw.fact_transactions f
group by date_trunc('week',f.transaction_dt)::Date
order by week_start;
---------------------------------------------------------
 -- Q5. Weekend  x weekday comparision

 select
 		case when d.is_weekend then 'Weekend' 
		 else 'Weekday' 							end as day_type,
		count(*) 							as txn_count,
		count(*) filter (where is_fraud)	as fraud_count,
		round(100 * count(*) filter (where is_fraud)
				/ count(*),2)				as frayd_rate_pct,
		round(avg(transaction_amt),2)		as avg_amount,
		round(sum(f.transaction_amt) filter 
					(where f.is_fraud),2)						as avg_fraud_amt
from fraud_dw.fact_transactions f
join fraud_dw.dim_date d using (date_id)
group by d.is_weekend
order by d.is_weekend;
----------------------------------------------------------------------

-- Q6. fraud time vary by product

SELECT 
    CASE 
        WHEN hour_of_day BETWEEN 0  AND 5  THEN '00-05 Night'
        WHEN hour_of_day BETWEEN 6  AND 11 THEN '06-11 Morning'
        WHEN hour_of_day BETWEEN 12 AND 17 THEN '12-17 Afternoon'
        WHEN hour_of_day BETWEEN 18 AND 23 THEN '18-23 Evening'
    END                                                 AS time_bucket,
    p.product_category,
    COUNT(*)                                            AS txn_count,
    COUNT(*) FILTER (WHERE f.is_fraud)                  AS fraud_count,
    ROUND(100.0 * COUNT(*) FILTER (WHERE f.is_fraud) 
                / COUNT(*), 3)                          AS fraud_rate_pct
FROM fraud_dw.fact_transactions f
JOIN fraud_dw.dim_product p USING (product_id)
GROUP BY 1, p.product_category
ORDER BY p.product_category, time_bucket;










		
		