-- Creating dimensional tables 
create schema if not exists fraud_dw;

-- verify both schemas now exist
select schema_name
from information_schema.schemata
where schema_name in ('staging','fraud_dw','public');

-------------------------------------------------

drop table if exits fraud_dw.dim_date cascade;

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
		to







