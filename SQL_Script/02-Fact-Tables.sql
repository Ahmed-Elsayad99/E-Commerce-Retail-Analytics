################################################################################
################################################################################
## " create table Fact_Orders "
create table Fact_Orders (
OrderID bigint auto_increment primary key,
Invoice bigint,
StockCode bigint,
Description_ varchar(225),
InvoiceDate datetime,
CustomerID bigint,
Country varchar(100),
Quantity int,
Price decimal(10,2),
Revenue decimal(10,2),
Profit_Proxy decimal(10,2)
);

INSERT INTO Fact_Orders (
    Invoice,
    StockCode,
    Description_,
    InvoiceDate,
    CustomerID,
    Country,
    Quantity,
    Price
)
SELECT
    Invoice,
    StockCode,
    Description_,
    InvoiceDate,
    CustomerID,
    Country,
    Quantity,
	Price
FROM Raw 
where 
  Quantity > 0
  AND Price > 0
  AND Description_ NOT LIKE '%DAMA%'
  AND Description_ NOT LIKE '%MISSIN%'
  AND Description_ NOT LIKE '%ADJUST%'
;

UPDATE Fact_Orders
SET Price = (
    SELECT AVG(Price) 
    FROM (SELECT Price FROM Fact_Orders WHERE Price > 0) AS temp
)
WHERE Price = 0;


select Count(*) from Fact_Orders
where Price=0 ;

# update "Revenue" and "Profit Proxy" #
update Fact_Orders 
set Revenue =  Quantity * Price ;

UPDATE Fact_Orders
SET Profit_Proxy = ROUND(
    CASE
        WHEN Price < 5 THEN Revenue * 0.25
        WHEN Price BETWEEN 5 AND 20 THEN Revenue * 0.30
        ELSE Revenue * 0.40
    END, 2
);

select * from Fact_Orders;

## Create backup for "orders" table ##
CREATE TABLE Orders_backup AS
SELECT * FROM Fact_Orders;

# delete Duplicates #
with Duplicates As (
   select OrderID,
    row_number()
    Over(partition by  Invoice, StockCode, Description_, InvoiceDate, CustomerID, Country, Quantity, Price, Revenue, Profit_Proxy
    order by OrderID )  As NUM 
  from Fact_Orders 
)
select count(*)
from Duplicates
where NUM > 1 ;

with Duplicates As (
   select OrderID,
    row_number()
    Over(partition by  Invoice, StockCode, Description_, InvoiceDate, CustomerID, Country, Quantity, Price, Revenue, Profit_Proxy
    order by OrderID )  As NUM 
  from Fact_Orders 
)
delete from Fact_Orders
where OrderID in ( 
   select OrderID
   from Duplicates
   where NUM > 1 );

#Check
select count(*) from Fact_Orders
where Quantity<0;

select * from Fact_Orders
where Description_ like '%DAMA%' or Description_ like '%MISSIN%' or Description_ like '%ADJUST%' ;
select Count(*) from Fact_Orders
where Description_ like '%DAMA%' or Description_ like '%MISSIN%' or Description_ like '%ADJUST%' ;

################################################################################
################################################################################
## Create "Fact_Returns" table ##
create table Fact_Returns (
ReturnID bigint auto_increment primary key,
Invoice bigint,
StockCode bigint,
Description_ varchar(225),
InvoiceDate datetime,
CustomerID bigint,
Country varchar(100),
Quantity int,
Price decimal(10,2),
Total_Amount decimal(10,2)
);


INSERT INTO Fact_Returns (
    Invoice,
    StockCode,
    Description_,
    InvoiceDate,
    CustomerID,
    Country,
    Quantity,
    Price
)
SELECT
    Invoice,
    StockCode,
    Description_,
    InvoiceDate,
    CustomerID,
    Country,
    Quantity,
	Price
FROM Raw 
where 
  Quantity < 0
  AND Description_ NOT LIKE '%DAMA%'
  AND Description_ NOT LIKE '%MISSIN%'
  AND Description_ NOT LIKE '%ADJUST%'
;

update Fact_Returns
set Quantity = 
       case 
          when Quantity < 0 then - Quantity
          else Quantity
		end;
        
        
update Fact_Returns
set Total_Amount = round(Quantity * Price , 2) ;


select * from Fact_Returns ;


with Duplicates As (
   select ReturnID,
    row_number()
    Over(partition by  Invoice, StockCode, Description_, InvoiceDate, CustomerID, Country, Quantity, Price, Total_Amount
    order by ReturnID )  As NUM 
  from Fact_Returns 
)
select count(*)
from Duplicates
where NUM > 1 ;

with Duplicates As (
   select ReturnID,
    row_number()
    Over(partition by  Invoice, StockCode, Description_, InvoiceDate, CustomerID, Country, Quantity, Price, Total_Amount
    order by ReturnID )  As NUM 
  from Fact_Returns 
)
delete from Fact_Returns
where ReturnID in ( 
   select ReturnID
   from Duplicates
   where NUM > 1 );


################################################################################
################################################################################
## Create "Losses" table ##
create table Fact_Adjustments (
AdjustmentID bigint auto_increment primary key,
Invoice bigint,
StockCode bigint,
Description_ varchar(225),
InvoiceDate datetime,
CustomerID bigint,
Country varchar(100),
Quantity int,
Price decimal(10,2),
Total_Amount decimal(10,2)
);

INSERT INTO Fact_Adjustments (
    Invoice,
    StockCode,
    Description_,
    InvoiceDate,
    CustomerID,
    Country,
    Quantity,
    Price
)
SELECT
    Invoice,
    StockCode,
    Description_,
    InvoiceDate,
    CustomerID,
    Country,
    Quantity,
	Price
FROM Raw 
where 
Description_ like '%DAMA%' or 
Description_ like '%MISSIN%' or 
Description_ like '%ADJUST%'
;

update Fact_Adjustments
set 
Quantity = case
				  when Quantity < 0 then -Quantity
                  else Quantity
				end,
Price = case
				  when Price < 0 then -Price
                  else Price
				end;

select * from Fact_Adjustments;
select Count(*) from Fact_Adjustments;

update Fact_Adjustments
set Total_Amount = round(Quantity * Price , 2) ;


with Duplicates As (
   select AdjustmentID,
    row_number()
    Over(partition by  Invoice, StockCode, Description_, InvoiceDate, CustomerID, Country, Quantity, Price, Total_Amount
    order by AdjustmentID )  As NUM 
  from Fact_Adjustments 
)
select count(*)
from Duplicates
where NUM > 1 ;

with Duplicates As (
   select AdjustmentID,
    row_number()
    Over(partition by  Invoice, StockCode, Description_, InvoiceDate, CustomerID, Country, Quantity, Price, Total_Amount
    order by AdjustmentID )  As NUM 
  from Fact_Adjustments 
)
delete from Fact_Adjustments
where AdjustmentID in ( 
   select AdjustmentID
   from Duplicates
   where NUM > 1 );
   


################################################################################
##  علشتان اربط الجداول fact مع Dim Date لازم كنت احول عمود invoicedate الى date بس مش datetime

UPDATE Fact_Orders
SET InvoiceDate = DATE(InvoiceDate);
ALTER TABLE Fact_Orders
MODIFY InvoiceDate DATE;
select * from fact_orders;


UPDATE fact_returns
SET InvoiceDate = DATE(InvoiceDate);
ALTER TABLE fact_returns
MODIFY InvoiceDate DATE;
select * from fact_returns;


UPDATE fact_adjustments
SET InvoiceDate = DATE(InvoiceDate);
ALTER TABLE fact_adjustments
MODIFY InvoiceDate DATE;
select * from fact_adjustments;

################################################################################
