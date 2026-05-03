-- Creating the tables matching our processed data

-- creating transaction table

drop table if exists staging.pros_transaction;

create table staging.pros_transaction(
	transaction_id	bigint primary key,
	is_fraud		smallint,
	transaction_dt	integer,
	transaction_amt	numeric(12,2),
	product_cd		varchar(4),
	card1			integer,
	card2			numeric,
	card3			numeric,
	card4			varchar(20),
	card5			numeric,
	card6 			varchar(20),
	addr1			numeric,
	addr2			numeric,
	dist1			numeric,
	dist2			numeric,
	p_emaildomain	varchar(50),
	r_emaildomain	varchar(50)
);


-- creating identity table

drop table if exists staging.pros_identity;

create table staging.pros_identity(
	transaction_id bigint primary key,
	device_type		varchar(20),
	device_info		varchar(100),
	id_30			varchar(50),
	id_31			varchar(100),
	id_33			varchar(20)
);

-------------------------
-- verify the tables

select table_schema, table_name,
		(select count(*) from information_schema.columns where table_schema = t.table_schema and table_name = t.table_name)
from 	information_schema.tables t
where table_schema = 'staging';
