-- Validity check to see does the data loaded properly

-- 1. Table row count - check

select 'pros_identity' AS table_name,count(*) as rows from staging.pros_identity
union all
select 'pros_transaction' , count(*) from staging.pros_transaction;

-- 2. Fraud rate

select  is_fraud,
		count(*) as cnt,
		sum(count(*)) over() as tot,
		round(100 * count(*)/sum(count(*)) over() ,2) as pct
from 	staging.pros_transaction
group by is_fraud
order by is_fraud;
