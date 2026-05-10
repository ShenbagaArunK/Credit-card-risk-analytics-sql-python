-- ETL for dimensional tables

-- ETL dim_card

insert into fraud_dw.dim_card(
	card1,card2, card3, card4, card5,card6,
	card_network, card_type
)
select distinct card1,card2,card3,card4,card5,card6,
-- Standardize and handle nulls
case
	when lower(trim(card4)) in ('visa','mastercard','american express', 'discover')
		then initcap(lower(trim(card4)))
	when card4 is null or trim(card4) = ''
		then 'Unknown'
	else 'Other'
end as card_network,

case 
	when lower(trim(card6)) in ('credit','debit')
		then initcap(lower(trim(card6)))
	when lower(trim(card6)) in ('debit or credit','charge card')
		then initcap(lower(trim(card6)))
	when card6 is null or trim(card6) = ''
		then 'Unknown'
	else 'Other'
end as card_type
from staging.pros_transaction;

-----------------------------------
-- Verifying
select count(*) as unique_cards from fraud_dw.dim_card;

select card_network, count(*) as card_count
from fraud_dw.dim_card
group by card_network
order by card_count desc;

----------------------------------------------------------------------

-- ETL dim_device

insert into fraud_dw.dim_device(
	device_type,device_info, operating_system, browser,screen_resolution
)
select distinct 
	coalesce(lower(trim(device_type)), 'unknown') 	as device_type,
	nullif(trim(device_info), '') 		as device_info,
	coalesce(lower(trim(id_30)), 'unknown') as operating_system,
	coalesce(lower(trim(id_31)), 'unknown') as browser,
	coalesce(trim(id_33), 'unknown') 		as screen_resolution
from staging.pros_identity;
-----------------------------------------------------------------------------
-- to avoid emty device_id -- filling it with unknown
insert into fraud_dw.dim_device(
	device_type,device_info, operating_system, browser,screen_resolution
	)
	values ('unknown',null,'unknown','unknown','unknown')
	on conflict do nothing;
-------------
-- verification

SELECT COUNT(*) AS unique_devices FROM fraud_dw.dim_device;

select device_type, count(*) as device_count
from fraud_dw.dim_device
group by device_type
order by 2 desc;

------------------------------------------------------------------------------------------

-- ETL dimensional geography

insert into fraud_dw.dim_geography(addr1,addr2,region_label,country_label)
select distinct addr1,addr2,
	case 
		when addr1 is null then 'Unknown Region'
		else 'Region_' || addr1::Text
	end as region_label,
	case 
		when addr2 is null then 'Unknown Country'
		when addr2 = 87 then 'Country_87 (US)'
		else 'Country_' || addr2::Text
	end as country_label
from staging.pros_transaction;
--------------------------
-- Verification
select count(*) as unique_geographies from fraud_dw.dim_geography;
-- got 438
-------------------
select country_label, count(*) as region_count
from fraud_dw.dim_geography
group by country_label
order by 2 desc
limit 10;

----------------------------------------------------------------------






