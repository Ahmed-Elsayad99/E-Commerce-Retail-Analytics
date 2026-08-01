#######################################################################################################
## Dim Customers ##
create table Dim_Customers (
ID bigint auto_increment primary key,
CustomerID bigint
);

insert into Dim_Customers (CustomerID)
select distinct CustomerID
from raw ;

select * from Dim_Customers;
select Count(*) as Tot_Count from Dim_Customers;

alter table Dim_Customers
add column First_Order_Date date;


with O As (
    select 
     CustomerID,
     Min(invoiceDate) As First_Order
	from Raw
    group by CustomerID )
update Dim_Customers D
join O
on D.CustomerID = O.CustomerID
set D.First_Order_Date = date(o.First_Order);

########################################################
## Dim Contry  ##
create table Dim_Contry (
ID bigint auto_increment primary key,
Country varchar(100)
);

insert into Dim_Contry (Country)
select distinct Country
from raw ;

select * from Dim_Contry;

delete from Dim_Contry 
where ID in (20,14,43,37);

########################################################
## Dim Products  ##
create table Dim_Products (
ID bigint auto_increment primary key,
StockCode bigint ,
Description_ varchar(225)
);

insert into Dim_Products (StockCode, Description_ )
select distinct 
    StockCode,
    max(Description_)
from raw 
group by StockCode;


with Duplicates As (
   select ID,
    row_number()
    Over(partition by  StockCode, Description_
    order by ID )  As NUM 
  from Dim_Products 
)
select count(*)
from Duplicates
where NUM > 1 ;

with Duplicates As (
   select ID,
    row_number()
    Over(partition by  StockCode, Description_
    order by ID )  As NUM 
  from Dim_Products 
)
delete from Dim_Products
where ID in ( 
   select ID
   from Duplicates
   where NUM > 1 );

SELECT StockCode, COUNT(*) AS cnt
FROM dim_products
GROUP BY StockCode
HAVING COUNT(*) > 1;

select * from Dim_Products;
select Count(*) as Tot_Count from Dim_Products;

########################################################
## Dim Date ##
# جي الطريقه الي عملتها علشان اعمل الجدول ده  بس منفعش علشان الموديل في الباور بي اي عايز التاريخ ميكونش فيه فجوات خالص فكان لازم الجا الي طريقه تانيه وهي بعد 
# الكويري دي

create table Dim_Date (
DateID bigint auto_increment primary key,
InvoiceDate date,
Year int,
Quarter int,
Month int,
MonthName varchar(50),
Day int
);


insert into Dim_Date (InvoiceDate, Year, Quarter, Month, MonthName, Day )
select distinct 
  date(InvoiceDate), 
  year(InvoiceDate) ,
  quarter(InvoiceDate) ,
  month(InvoiceDate) ,
  monthname(InvoiceDate) ,
  day(InvoiceDate)
from raw 
order by date(InvoiceDate);


select * from Dim_Date
order by InvoiceDate asc;

#################################################################
## والطريقه اهي 
CREATE OR REPLACE VIEW vw_Date_Range AS
SELECT
    MIN(DATE(InvoiceDate)) AS MinDate,
    MAX(DATE(InvoiceDate)) AS MaxDate
FROM raw;



CREATE TABLE Dim_Date AS
WITH RECURSIVE Dates AS (
    SELECT MinDate AS InvoiceDate
    FROM vw_Date_Range

    UNION ALL

    SELECT DATE_ADD(InvoiceDate, INTERVAL 1 DAY)
    FROM Dates
    WHERE InvoiceDate < (SELECT MaxDate FROM vw_Date_Range)
)
SELECT
    InvoiceDate,
    YEAR(InvoiceDate) AS Year,
    QUARTER(InvoiceDate) AS Quarter,
    MONTH(InvoiceDate) AS Month,
    MONTHNAME(InvoiceDate) AS MonthName,
    DAY(InvoiceDate) AS Day
FROM Dates
order by InvoiceDate asc;

ALTER TABLE dim_date
add column DateID bigint auto_increment primary key;


with Duplicates As (
   select DateID,
    row_number()
    Over(partition by  InvoiceDate, Year, Quarter, Month, MonthName, Day
    order by DateID )  As NUM 
  from dim_date 
)
select count(*)
from Duplicates
where NUM > 1 ;

with Duplicates As (
   select DateID,
    row_number()
    Over(partition by  InvoiceDate, Year, Quarter, Month, MonthName, Day
    order by DateID )  As NUM 
  from dim_date 
)
delete from dim_date
where DateID in ( 
   select DateID
   from Duplicates
   where NUM > 1 );
