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

-- 










	
