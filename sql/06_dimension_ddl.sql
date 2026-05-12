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
	('S', 'Subscription'),
	('R', 'Retail');

-----------------------------------
-- verify
select * from fraud_dw.dim_product;

-------------------------------------------------------------

-- Dimensio Card

drop table if exists fraud_dw.dim_card cascade;

create table fraud_dw.dim_card(
	card_id		serial primary key,
	card1 		integer,
	card2		numeric,
	card3		numeric,
	card4		varchar(25),
	card5		numeric,
	card6		varchar(10),
	card_network	varchar(25),
	card_type		varchar(10)
);

-- Indexong the card table for ETL process
create unique index idx_dim_card_natural
	on fraud_dw.dim_card(
		coalesce(card1, -1),
		coalesce(card2, -1),
		coalesce(card3, -1),
		coalesce(card4, ''),
		coalesce(card5, -1),
		coalesce(card6, '')
	);


select * from fraud_dw.dim_card;
---------------------------------------------------------------------


-- Diensions Device

drop table if exists fraud_dw.dim_device cascade;

create table fraud_dw.dim_device (
	device_id			serial primary key,
	device_type			varchar(20),
	device_info			varchar(200),
	operating_system	varchar(50),
	browser				varchar(100),
	screen_resolution	varchar(20)
);

create unique index idx_dim_device_natural
	on fraud_dw.dim_device(
		coalesce(device_type, ''),
		coalesce(device_info, ''),
		coalesce(operating_system, ''),
		coalesce(browser, ''),
		coalesce(screen_resolution, '')
	);


----------------------------------------------------------------

-- Dmensional Geography

drop table if exists fraud_dw.dim_geography cascade;

create table fraud_dw.dim_geography(
	geography_id 	serial primary key,
	addr1			numeric,
	addr2			numeric,
	region_label	varchar(50),
	country_label	varchar(50)
);

create unique index idx_dim_geography_natural
	on fraud_dw.dim_geography(
		coalesce(addr1, -1),
		coalesce(addr2, -1)
	);

------------------------------------------------------------------

drop table if exists fraud_dw.dim_email_domain cascade;

create table fraud_dw.dim_email_domain(
	email_domain_id		serial primary key,
	email_domain		varchar(50) unique,
	domain_category		varchar(30)
);
-----------------------------------------------------------------

select table_name,
		(select count(*) from information_schema.columns
		where table_schema = 'fraud_dw' and table_name = t.table_name) as columns_count

from information_schema.tables t
where table_schema = 'fraud_dw'
order by table_name

----------------------------------------------------------------
