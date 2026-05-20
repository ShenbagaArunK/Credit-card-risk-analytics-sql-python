-- Transactions Speed and the numbers in given intervals

-- Q1. Transactions counts per card for 1hr, 24hr and 1 week

select
		transaction_id,
		card_id,
		transaction_dt,
		is_fraud,
		transaction_amt,

		count(*) over (partition by card_id
						order by transaction_dt
						range between interval '1 hour' preceding and current row)
						as txns_last_1hr,

		count(*) over (partition by card_id
						order by transaction_dt
						range between interval '24 hour' preceding and current row)
						as txns_last_24hr,

		count(*) over (partition by card_id
						order by transaction_dt
						range between interval '7 days' preceding and current row)
						as txns_last_7d
from fraud_dw.fact_transactions
order by txns_last_1hr desc;

-----------------------------------------------------------------------

-- Q2. Per card spend in 1hr, 24hr and 7 days

select
		transaction_id,
		card_id,
		transaction_dt,
		is_fraud,
		transaction_amt,

		round(sum(transaction_amt) over (partition by card_id
						order by transaction_dt
						range between interval '1 hour' preceding and current row),2)
						as amt_last_1hr,

		round(sum(transaction_amt) over (partition by card_id
						order by transaction_dt
						range between interval '24 hour' preceding and current row),2)
						as amt_last_24hr,

		round(sum(transaction_amt) over (partition by card_id
						order by transaction_dt
						range between interval '7 days' preceding and current row),2)
						as amt_last_7d
from fraud_dw.fact_transactions
order by amt_last_1hr desc;
------------------------------------------------------------------

-- Q3. Fraud rate by transaction count
with velocity as (
	select transaction_id,
			is_fraud,
			count(*) over (partition by card_id
					order by transaction_dt
					range between interval '1 hour' preceding and current row)
					as txns_last_1hr
	from fraud_dw.fact_transactions
)

select 
	case
		when txns_last_1hr = 1 then '1 txn'
		when txns_last_1hr = 2 then '2 txns'
		when txns_last_1hr = 3 then '3 txns'
		when txns_last_1hr between 4 and 5 then '4-5 txns'
		when txns_last_1hr between 6 and 10 then '6-10 txns'
		else '10+ txns'
	end 							as velocity_bucket,
	count(*)						as txn_count,
	count(*) filter(where is_fraud) as fraud_count,
	round(100 * count(*) filter(where is_fraud)
			/ count(*))				as fraud_rate_pct

from velocity
group by velocity_bucket
order by Min(txns_last_1hr);
-----------------------------------------------------------------------------------

-- Q4. Baseline count of transaction for per card

with velocity as (
	select transaction_id,
			card_id,
			transaction_dt,
			is_fraud,
			count(*) over (partition by card_id
					order by transaction_dt
					range between interval '1 hour' preceding and current row)
					as txns_last_1hr
	from fraud_dw.fact_transactions
),
card_baseline as (
	select card_id,
	-- chking 95% times the card txn count to comapre
			percentile_cont(0.95) within group
					(order by txns_last_1hr) as pct_95_velocity,
			avg(txns_last_1hr) as avg_velovity
	from velocity
	group by card_id
)
select 
	case
		when v.txns_last_1hr > cb.pct_95_velocity and pct_95_velocity >1
			then 'Above own pct_95'
			else 'Normal for cards'
			end 																as velocity_status,
	count(*)										as txn_count,
	count(*) filter (where is_fraud) 				as fraud_count,
	round(100 * count(*) filter(where is_fraud)
			/ count(*))								as fraud_rate_pct

from velocity v join card_baseline cb
using (card_id)
group by velocity_status
order by fraud_rate_pct desc;
-------------------------------------------------------------------------------------------------

-- Q5. Top 20 cards with most movement

with velocity as (
	select
			transaction_id,
			card_id,
			transaction_dt,
			is_fraud,
			transaction_amt,

			count(*) over (partition by card_id
						order by transaction_dt
						range between interval '1 hour' preceding and current row)
						as txns_last_1hr,

			round(sum(transaction_amt) over (partition by card_id
						order by transaction_dt
						range between interval '1 hour' preceding and current row),2)
						as amt_last_1hr
from fraud_dw.fact_transactions
)
select 
		card_id,
		transaction_dt,
		txns_last_1hr,
		amt_last_1hr,
		is_fraud
from velocity
order by txns_last_1hr desc, amt_last_1hr desc
limit 20;
-------------------------------------------------------------------------


-- hypothesis Test -- velocity does not relate to increase the fraud rate

-- How many transactions does each card_id carry?
SELECT 
    transaction_count_bucket,
    COUNT(*) AS num_cards
FROM (
    SELECT 
        card_id,
        CASE 
            WHEN COUNT(*) = 1 THEN '1 txn'
            WHEN COUNT(*) BETWEEN 2 AND 10 THEN '2-10'
            WHEN COUNT(*) BETWEEN 11 AND 50 THEN '11-50'
            WHEN COUNT(*) BETWEEN 51 AND 200 THEN '51-200'
            ELSE '200+'
        END AS transaction_count_bucket
    FROM fraud_dw.fact_transactions
    GROUP BY card_id
) t
GROUP BY transaction_count_bucket
ORDER BY MIN(
    CASE transaction_count_bucket
        WHEN '1 txn' THEN 1 WHEN '2-10' THEN 2 
        WHEN '11-50' THEN 3 WHEN '51-200' THEN 4 ELSE 5 END
);



-- The busiest card_ids — how many transactions?
SELECT card_id, COUNT(*) AS txn_count
FROM fraud_dw.fact_transactions
GROUP BY card_id
ORDER BY txn_count DESC
LIMIT 10;



-- from this, In this dataset card_id deos not indicating one card but a cluster of cards based on banks or region.


-- per-card transaction volume vs fraud rate
-- Shows that high-volume card_ids are LOW fraud (they're popular legit clusters)

SELECT 
    CASE 
        WHEN card_txn_count BETWEEN 1 AND 10    THEN '1-10'
        WHEN card_txn_count BETWEEN 11 AND 50   THEN '11-50'
        WHEN card_txn_count BETWEEN 51 AND 200  THEN '51-200'
        ELSE '200+'
    END                                                AS card_volume_tier,
    COUNT(*)                                           AS txn_count,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_fraud) 
                / COUNT(*), 3)                         AS fraud_rate_pct
FROM fraud_dw.fact_transactions f
JOIN (
    SELECT card_id, COUNT(*) AS card_txn_count
    FROM fraud_dw.fact_transactions
    GROUP BY card_id
) cv USING (card_id)
GROUP BY card_volume_tier
ORDER BY MIN(card_txn_count);
--------------------------------------------------------