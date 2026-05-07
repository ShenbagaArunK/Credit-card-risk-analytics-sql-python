-- Validity check to see does the data loaded properly

-- 1. Table row count - check

select 'pros_identity' AS table_name,count(*) as rows from staging.pros_identity
union all
select 'pros_transaction' , count(*) from staging.pros_transaction;

-------------------------------------------------------------------------

-- 2. Fraud rate

select  is_fraud,
		count(*) as cnt,
		sum(count(*)) over() as tot,
		round(100 * count(*)/sum(count(*)) over() ,2) as pct
from 	staging.pros_transaction
group by is_fraud
order by is_fraud;

------------------------------------------------------------------------

-- 3. Check Date range
-- from kaggle site we got the initial date, with that we are adding the seconds given (86400 --> 1 day)
SELECT 
    transaction_id,
    transaction_dt                                                      AS raw_offset,
    '2017-12-01'::timestamp + transaction_dt * INTERVAL '1 second'      AS real_timestamp
FROM staging.pros_transaction
ORDER BY transaction_dt
LIMIT 5;

------

select 
		min('2017-12-01'::timestamp + transaction_dt * Interval '1 second') as start_date,
		max('2017-12-01'::timestamp + transaction_dt * Interval '1 second') as start_date
from
		staging.pros_transaction;
--------------------------------------------------------------------------

-- 4. Join coverage

select 
		count(*) as total,
		count(i.transaction_id) as with_identity,
		round(100 * count(i.transaction_id)/count(*),2) as percent_with_identity
from 
	staging.pros_transaction t left join staging.pros_identity i
using	(transaction_id);
-------------------------------------------------------------------------

-- 5. Card Network value counts

select 
		card4 as card_name,
		count(card4) as count_of_cards
from
		staging.pros_transaction
group by card4
order by 2 desc;
-------------------------------------------------------------------------

-- 6. Top email domains

select 
		p_emaildomain,
		count(*) as cnt,
		round(100 * count(*) filter(where is_fraud = 1) / count(*),2) as fraud_rate_pect
from
		staging.pros_transaction
where p_emaildomain is not null
group by p_emaildomain
order by 2 desc
limit 10;
-------------------------------------------------------------------------