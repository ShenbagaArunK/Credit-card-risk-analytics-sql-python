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