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
