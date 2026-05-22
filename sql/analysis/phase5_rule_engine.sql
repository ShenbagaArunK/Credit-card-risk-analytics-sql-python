--- Phase 05: Rule based fraud Detection Engine
-- rules derived from pase 4 discovered segments
CREATE OR REPLACE VIEW fraud_dw.v_scored_transactions AS
with enriched as (
	select
		f.transaction_id,
		f.is_fraud,
		f.transaction_amt,
		p.product_category,
		c.card_type,
		d.device_type,
		e.domain_category,
		ntile(5) over (order by f.transaction_amt)			as amt_quintile
	from fraud_dw.fact_transactions f 
	join fraud_dw.dim_product p using (product_id)
	join fraud_dw.dim_card c using (card_id)
	join fraud_dw.dim_device d using (device_id)
	join fraud_dw.dim_email_domain e  
	 on f.purchase_email_id = e.email_domain_id
),
scored as (
	select *, 
	-- Each rule will contributes points
	-- Rule - 01
	-- CNP + credit + free_webmail + High value
	case when product_category = 'Card-Not-Present'
		and card_type = 'Credit'
		and domain_category = 'free_webmail'
		and amt_quintile = 5
		then 26 else 0 end as r1,
		
	-- R2: Hotel/Travel + free_webmail + high value
	case when product_category = 'Hotel/Travel'
	and domain_category = 'free_webmail'
	and amt_quintile = 5
	then 24 else 0 end as r2,

	-- R3: CNP + Credit + free_webmail, any value
	case when product_category = 'Card-Not-Present'
	and card_type = 'Credit'
	and domain_category = 'free_webmail'
	then 18 else 0 end as r3,

	-- R4: CNP + Credit + unknown device + Normal balue
	case when product_category = 'Card-Not-Present'
	and card_type = 'Credit'
	and device_type = 'unknown'
	then 20 else 0 end as r4,

	-- R5: anonymous email + CNP
	case when domain_category = ' anonymous'
	and product_category = 'Card-Not-Present'
	then 11 else 0 end as r5,

	-- R6.extreme amount (Bottom and top quintile) + free_webmail + CNP
	case when product_category = 'Card-Not-Present'
	and domain_category = 'free_webmail'
	and amt_quintile in (1,5)
	then 8 else 0 end as r6
from enriched
)
select 
		transaction_id,
		is_fraud,
		transaction_amt,
		r1,r2,r3,r4,r5,r6,
		(r1+r2+r3+r4+r5+r6) as risk_score
from scored;

------------------------------------------------------------------------------------
-- checks

-- does fraud_transactios got higher score
select
	is_fraud,
	count(*) 							as txn_count,
	round(avg(risk_score),2) 			as avg_score,
	round(percentile_cont(0.50) 
	within group (order by risk_score)::numeric,1) 		as median_score,
	max(risk_score)						as max_score
from fraud_dw.v_scored_transactions
group by is_fraud
order by is_fraud;
-----------------------------------------

-- Setting up confusion matrix with threshold

with evaluation as (
	select 
		is_fraud,
		(risk_score >= 18) as flagged
	from fraud_dw.v_scored_transactions
)
select
	count(*) filter (where flagged and is_fraud) 			as true_positives,
	count(*) filter (where flagged and not is_fraud)		as flase_positives,
	count(*) filter (where not flagged and is_fraud)		as flase_negatives,
	count(*) filter (where not flagged and not is_fraud)	as true_negative,

	-- How many were actullay fraud out of flagged
	round(100.0 * count(*) filter (where flagged and is_fraud)::numeric
		/ nullif(count(*) filter (where flagged),0),2)	as precesion_pct,
		
	-- recall : of all fraud hw manu did we got right
	round(100.0 * count(*) filter (where flagged and is_fraud)::numeric
		/ nullif(count(*) filter (where is_fraud),0),2)		as recall_pct

from evaluation;
--------------------------------------------------------------------------
	
-- F1 score

with thresholds as (
select generate_series(0,60,2) as threshold
),
metrics as (
	select t.threshold,
	count(*) filter (where s.risk_score >= threshold and s.is_fraud) 	as tp,
	count(*) filter (where s.risk_score >= threshold and not s.is_fraud) 	as fp,
	count(*) filter (where is_fraud)										as tot_fraud
from thresholds t
	cross join fraud_dw.v_scored_transactions s
group by t.threshold,
	(select count(*) filter (where is_fraud) from fraud_dw.v_scored_transactions)		
)
select 
	threshold,
	tp,
	fp,
	round(100.0 * tp::numeric / nullif(tp + fp,0),2) as precesion_pct,
	round(100.0 * tp::numeric / nullif(tot_fraud,0),2) as recall_pct,
	-- F1 score
	round(2.0 * (tp::numeric/nullif(tp+fp,0)) * (tp::numeric / NULLIF(tot_fraud, 0))
		/NULLIF((tp::numeric / NULLIF(tp + fp, 0)) + (tp::numeric / NULLIF(tot_fraud, 0)), 0) * 100, 2) as f1_score
from metrics
order by threshold;

-------------------------------------------------------------------------------------------------------

-- Cost Benefit analysis

with evaluation as (
	select 
		is_fraud,
		transaction_amt,
		(risk_score >= 18) as flagged
	from fraud_dw.v_scored_transactions
)
select
	-- Fraud Caught -- led to saving money
	round(sum(transaction_amt) filter (where flagged and is_fraud),2) as fraud_value_caught,
	-- Fraud missed - led to losing money
	round(sum(transaction_amt) filter (where not flagged and is_fraud),2) as fraud_value_missed,
	-- Predicted wrong (False positives x $5(assumption))
	(count(*) filter (where flagged and not is_fraud) * 5)					as friction_cost,
	-- Net benefit
	round(sum(transaction_amt) filter (where flagged and is_fraud)
		- count(*) filter (where flagged and not is_fraud)*5,2)				as net_benefit
from evaluation;




	
