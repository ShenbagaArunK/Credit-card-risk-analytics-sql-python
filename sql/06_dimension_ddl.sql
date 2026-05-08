-- Creating dimensional tables 
create schema if not exists fraud_dw;

-- verify both schemas now exist
select schema_name
from information_schema.schemata
where schema_name in ('staging','fraud_dw','public');

-------------------------------------------------

drop table if exists fraud_dw.dim_date cascade;

create table fraud_dw.dim_date(
	date_id		integer primary key,
	full_date	date not null unique,
	year		smallint not null,
	quarter		smallint not null,
	month		smallint not null,
	month_name	varchar(10) not null,
	week_of_year	smallint not null,
	day_of_month	smallint not null,
	day_of_week		smallint not null,
	day_name		varchar(15) not null,
	is_weekend		boolean not null,
	is_month_end	boolean not null
);

-- Inserting data into dim_date

insert into fraud_dw.dim_date
select
		to_char(d, 'YYYYMMDD')::integer		as date_id,
		d									as full_date,
		extract(year from d)::smallint		as year,
		extract(Quarter from d)::smallint	as quarter,
		extract(month from d)::smallint		as month,
		trim(to_char(d, 'Month'))			as month_name,
		extract(week from d)::smallint		as week_of_year,
		extract(day from d)::smallint		as day_of_month,
		extract(dow from d)::smallint		as day_of_week,
		trim(to_char(d,'Day'))				as day_name,
		extract(Dow from d) in (0,6)		as is_weekend,
		d = (DATE_TRUNC('month', d) + INTERVAL '1 month - 1 day')::DATE 	as is_month_end

from 	Generate_Series('2017-12-01'::Date, '2018-12-31'::Date, '1 day') as d;

---------------------------
-- verifying

select count(*) as total_days from fraud_dw.dim_date;

--------------------------------------------------------------

-- decoded the product category from kaggle data

drop table if exists fraud_dw.dim_product cascade;

create table fraud_dw.dim_product(
	product_id		Serial Primary Key,
	product_cd 		varchar(4) unique not null,
	product_category varchar(50) not null
);

-------------------

Insert into fraud_dw.dim_product (product_cd,product_category) values
	('W', 'Web Purchase'),
	('H', 'Hotel/Travel'),
	('C', 'Card-Not-Present'),
	('S', 'Subscritption'),
	('R', 'Retail');

-----------------------------------
-- verify
select * from fraud_dw.dim_product;

-------------------------------------------------------------







