
create database Online_Retail;
use Online_Retail;
create table Raw (
Invoice varchar(100),
StockCode varchar(100),
Description_ varchar(225),
Quantity varchar(100),
InvoiceDate varchar(100),
Price varchar(100),
CustomerID varchar(100),
Country varchar(100)
);

SHOW VARIABLES LIKE "secure_file_priv";

SHOW VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 'ON';

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 9.6\\Uploads\\online A1.csv'
INTO TABLE Raw
FIELDS TERMINATED BY ','
IGNORE 1 LINES;

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 9.6\\Uploads\\online A2.csv'
INTO TABLE Raw
FIELDS TERMINATED BY ','
IGNORE 1 LINES;

################################################################################
# CHECK "Description_" #

UPDATE Raw
SET Description_ = trim(replace(REPLACE(Description_,'?',''),'*',''));
UPDATE Raw
SET Description_ =
TRIM(
    REGEXP_REPLACE(Description_, '\\s+', ' ')
);

SELECT
    COUNT(*) AS total_rows,
    SUM(Description_ <> '') AS not_nulls,
    SUM(Description_ IS NULL) AS nulls,
    SUM(Description_ = '') AS empty_strings,
	SUM(TRIM(Description_) = ' ') AS spaces_only
FROM Raw;

update Raw
set Description_ = coalesce(nullif(Description_,''), 'UNKNOWN');
update Raw
set Description_ = upper(Description_);

################################################################################
# CHECK "StockCode" AND "Invoice" #

UPDATE Raw
SET StockCode = REGEXP_REPLACE(StockCode, '[^0-9]', '');
UPDATE Raw
SET Invoice = REGEXP_REPLACE(Invoice, '[^0-9]', '');

update Raw
set StockCode = coalesce(nullif(StockCode,''), 11111);

SELECT
    COUNT(*) AS total_rows,
    SUM(Invoice <> '') AS not_nulls,
    SUM(Invoice IS NULL) AS nulls,
    SUM(Invoice = '') AS empty_strings,
	SUM(TRIM(Invoice) = ' ') AS spaces_only
FROM Raw;

SELECT
    COUNT(*) AS total_rows,
    SUM(StockCode <> '') AS not_nulls,
    SUM(StockCode IS NULL) AS nulls,
    SUM(StockCode = '') AS empty_strings,
	SUM(TRIM(StockCode) = ' ') AS spaces_only
FROM Raw;

################################################################################
# CHECK "CustomerID" #

SELECT
    COUNT(*) AS total_rows,
    SUM(CustomerID <> '') AS not_nulls,
    SUM(CustomerID IS NULL) AS nulls,
    SUM(CustomerID = '') AS empty_strings,
	SUM(TRIM(CustomerID) = ' ') AS spaces_only
FROM Raw;

update Raw 
set CustomerID = coalesce(nullif(CustomerID,''),00000) ;

update Raw 
set CustomerID = trim(CustomerID) ;

# Check "Country" # 
update Raw 
set Country = trim(Country) ;
update Raw 
set Country = upper(Country) ;

################################################################################
# CHECK "Quantity" #

SELECT
    COUNT(*) AS total_rows,
    SUM(Quantity > 0) AS p_values,
    SUM(Quantity < 0) AS n_values
FROM Raw;

################################################################################
# CHECK "Price" #

SELECT
    COUNT(*) AS total_rows,
    SUM(Price = 0) AS Z_strings,
	SUM(Price > 0) AS p_values,
    SUM(Price < 0) AS n_values
FROM Raw;

select * from Raw
where price <0 ;

select count(*) from Raw
where price =0 ;
select * from Raw
where price =0;

## Compensation for prices that do have prices ##

with Avg_Prices as (
select StockCode, avg(price) as Avg_Price
from Raw 
where Price > 0 
group by StockCode
)
update Raw R
join Avg_Prices A
on R.StockCode  = A.StockCode
set R.price = A.Avg_Price
where price = 0 ;

## Compensation for prices that have no prices ##

select count(*) from Raw
where price =0 ;
select * from Raw
where price =0;

UPDATE Raw
SET Price = (
    SELECT AVG(Price) 
    FROM (SELECT Price FROM Raw WHERE Price > 0) AS temp
)
WHERE Price = 0;


################################################################################
select * from Raw
where Description_ like '%DAMA%' or Description_ like '%MISSIN%' or Description_ like '%ADJUST%' ;
select Count(*) from Raw
where Description_ like '%DAMA%' or Description_ like '%MISSIN%' or Description_ like '%ADJUST%' ;

SELECT
    COUNT(*) AS total_rows,
    SUM(Quantity > 0) AS p_values,
    SUM(Quantity < 0) AS n_values
FROM Raw;

select * from Raw
where price <0 ;

###########################################################################################################################
####################################################################################################################
# CHECK "InvoiceDate" # 

UPDATE raw
SET InvoiceDate = STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i');

ALTER TABLE raw
MODIFY Price DECIMAL(10,2);    

ALTER TABLE raw
MODIFY Invoice BIGINT UNSIGNED,
MODIFY StockCode BIGINT UNSIGNED,
MODIFY CustomerID BIGINT UNSIGNED,
MODIFY Quantity INT,
MODIFY InvoiceDate DATETIME;



