#################################################################################################
## 'Net Revenue' ##

with Orders as (
 select sum(Revenue) as Total_Revenue
 from Fact_Orders ),
 
Returns_ as (
 select sum(Total_Amount) as Total_Returns
 from Fact_Returns ),

Adjustments as (
 select sum(Total_Amount) as Total_Adjustments
 from Fact_Adjustments )
 
 select 
  O.Total_Revenue as Total_Revenue ,
  R.Total_Returns as Total_Returns ,
  A.Total_Adjustments as Total_Adjustments,
  O.Total_Revenue - R.Total_Returns - A.Total_Adjustments AS Net_Revenue
from Orders O
cross join Returns_ R
cross join Adjustments A
;

##################################################################################################
## " Net Revenue By Customers " ##

CREATE VIEW VW_Net_Revenue_Per_Customer AS
with Orders As (
  select CustomerID, sum(Revenue) As Total_Revenue
  from Fact_Orders
  group by CustomerID ),
  
  Returns_ As (
  select CustomerID, sum(Total_Amount) As Total_Returns
  from Fact_Returns
  group by CustomerID ),

  Adjustments As (
  select CustomerID, sum(Total_Amount) As Total_Adjustments
  from Fact_Adjustments
  group by CustomerID )
  
select 
  O.CustomerID,
  O.Total_Revenue,
  coalesce( R.Total_Returns ,0) as Total_Returns,
  coalesce( A.Total_Adjustments ,0) as Total_Adjustments,
  O.Total_Revenue - coalesce( R.Total_Returns ,0) - coalesce( A.Total_Adjustments ,0) As Net_Revenue
from Orders O
left join Returns_ R  on O.CustomerID = R.CustomerID
left join Adjustments A  on O.CustomerID = A.CustomerID
order by Net_Revenue desc ;

select * from VW_Net_Revenue_Per_Customer ;

SELECT *
FROM vw_net_revenue_per_customer
WHERE net_revenue < 0;


##################################################################################################
## " Net Revenue By Products " ##

CREATE VIEW VW_Net_Revenue_Per_Product AS
with Orders As (
  select StockCode, sum(Revenue) As Total_Revenue
  from Fact_Orders
  group by StockCode ),
  
  Returns_ As (
  select StockCode, sum(Total_Amount) As Total_Returns
  from Fact_Returns
  group by StockCode ),

  Adjustments As (
  select StockCode, sum(Total_Amount) As Total_Adjustments
  from Fact_Adjustments
  group by StockCode )
  
select 
  O.StockCode,
  O.Total_Revenue,
  coalesce( R.Total_Returns ,0) as Total_Returns,
  coalesce( A.Total_Adjustments ,0) as Total_Adjustments,
  O.Total_Revenue - coalesce( R.Total_Returns ,0) - coalesce( A.Total_Adjustments ,0) As Net_Revenue
from Orders O
left join Returns_ R  on O.StockCode = R.StockCode
left join Adjustments A  on O.StockCode = A.StockCode
order by Net_Revenue desc ;

select * from VW_Net_Revenue_Per_Product ;


SELECT *
FROM VW_Net_Revenue_Per_Product
WHERE net_revenue < 0;

##################################################################################################
##################################################################################################
## " Monthly Net Revenue Trend " ##

CREATE VIEW VW_Monthly_Net_Revenue_Trend AS
with Orders As (
  select 
    year(InvoiceDate) as Year,
    monthname(InvoiceDate) as Month, 
    sum(Revenue) As Total_Revenue
  from Fact_Orders
  group by Year,Month ),
  
  Returns_ As (
  select 
    year(InvoiceDate) as Year,
    monthname(InvoiceDate) as Month,
    sum(Total_Amount) As Total_Returns
  from Fact_Returns
  group by Year,Month ),

  Adjustments As (
  select 
    year(InvoiceDate) as Year,
    monthname(InvoiceDate) as Month, 
    sum(Total_Amount) As Total_Adjustments
  from Fact_Adjustments
  group by Year,Month )
  
select 
  O.Year,
  O.Month,
  O.Total_Revenue,
  coalesce( R.Total_Returns ,0) as Total_Returns,
  coalesce( A.Total_Adjustments ,0) as Total_Adjustments,
  O.Total_Revenue - coalesce( R.Total_Returns ,0) - coalesce( A.Total_Adjustments ,0) As Net_Revenue
from Orders O
left join Returns_ R  
on O.Year = R.Year 
and O.Month = R.Month
left join Adjustments A  
on O.Year = A.Year
and O.Month = A.Month
order by Net_Revenue desc ;

select * from VW_Monthly_Net_Revenue_Trend ;

#################################################################
Create View Monthly_Kpis As
with Orders As (
			Select 
                year(InvoiceDate) As Year,
                quarter(InvoiceDate) As Quarter,
                month(InvoiceDate) As Month,
                count(distinct CustomerID) As Total_Customers,
                Count(distinct invoice) As Total_Orders,
                Sum(Revenue) As Total_Revenue
			From Fact_Orders
            group by year(InvoiceDate), quarter(InvoiceDate) ,month(InvoiceDate) ),
   Returns_ As (
            select 
				year(InvoiceDate) As Year,
                quarter(InvoiceDate) As Quarter,
                month(InvoiceDate) As Month,
                sum(Total_Amount) As Total_Returns
			From Fact_Returns
            group by year(InvoiceDate), quarter(InvoiceDate),month(InvoiceDate) ),
Adjustments As (
            select 
                year(InvoiceDate) AS Year,
                quarter(InvoiceDate) AS Quarter,
                month(InvoiceDate) As Month,
                Sum(Total_Amount) As Total_Adjustments
			From Fact_Adjustments
            group by year(InvoiceDate), quarter(InvoiceDate),month(InvoiceDate) )

select 
    O.Year,
    O.Quarter,
    O.month,
    O.Total_Customers,
    O.Total_Orders,
    O.Total_Revenue,
    coalesce(R.Total_Returns,0) As Total_Returns,
    O.Total_Revenue - coalesce(R.Total_Returns,0) - coalesce(A.Total_Adjustments,0)  As Net_Revenue,
    round(coalesce(R.Total_Returns,0) / O.Total_Revenue * 100 , 2) As Return_Rate,
    round(O.Total_Revenue / O.Total_Customers ,2) As Avg_Revenue_Per_Customer
From Orders O
left join Returns_ R
   On O.Year = R.Year 
   And O.Quarter = R.Quarter
   And O.month = R.month
left join Adjustments A
   On O.Year = A.Year 
   And O.Quarter = A.Quarter
   And O.month = A.month
order By  O.Year, O.Quarter, O.month ;

select * 
from monthly_kpis 
order by Year,Quarter ,month;

###################################################################
##################################################################################################
create or replace view vw_product_segment_yearly as
with Raw As (
         select distinct
             StockCode,
             year(InvoiceDate) as Year
		 from raw
),
 Orders as (
    select
        year(InvoiceDate) as Year,
        StockCode,
        Sum(Quantity) As Total_Qty_Sold,
        sum(Revenue) as Total_Revenue
    from Fact_orders
    group by Year, StockCode
),
Returns as (
    select
        year(InvoiceDate) as Year,
        StockCode,
        Sum(Quantity) As Total_Qty_Returned,
        sum(Total_Amount) as Total_Returns
    from fact_returns
    group by Year, StockCode
),
Adjust AS (
      select 
         year(InvoiceDate) as Year,
         StockCode,
         sum(Total_Amount) as Total_Adjustments
	  from fact_adjustments
      group by Year, StockCode
),
Base as (
    select
        Raw.Year,
        Raw.StockCode,
        coalesce(O.Total_Qty_Sold, 0) As Total_Qty_Sold,
        coalesce(O.Total_Revenue, 0) As Total_Revenue,
        coalesce(R.Total_Qty_Returned, 0) as Total_Qty_Returned,
        coalesce(R.Total_Returns, 0) as Total_Returns,
        coalesce(O.Total_Revenue, 0) - coalesce(R.Total_Returns, 0) - coalesce(A.Total_Adjustments, 0)
         As Net_Revenue
    from Raw 
    left join Orders O
        on Raw.StockCode = O.StockCode
       and Raw.Year = O.Year
    left join Returns R
        on Raw.StockCode = R.StockCode
       and Raw.Year = R.Year
	left join Adjust A
        on Raw.StockCode = A.StockCode
       and Raw.Year = A.Year
)
select
    Year,
    StockCode,
    Total_Qty_Sold,
    Total_Revenue,
    Total_Qty_Returned,
    Total_Returns,
    Round( Total_Returns / greatest(Total_Revenue ,1) ,2) AS Return_Rate,
    Net_Revenue,
    case
      when StockCode = 11111 then 'Unknown_Product'
      when 
          Total_Revenue = 0 AND Total_Returns > 0
          Or Total_Revenue < Total_Returns
	    then 'Critical'
      WHEN Total_Returns > Total_Revenue * 0.7 THEN 'Warning'
      WHEN Total_Revenue > 80000 AND Total_Returns >= 20000 THEN 'At_Risk'
      WHEN Total_Revenue > 80000 AND Total_Returns <= 3000 THEN 'Hero' 
      WHEN Total_Revenue <= 2000 THEN 'Inactive'
      ELSE 'Healthy'
    END AS Product_Segment
from Base;

select
  StockCode,
  Sum(Total_Revenue)
from vw_product_segment_yearly
group by StockCode
order by Sum(Total_Revenue) desc ;

select * from vw_product_segment_yearly;

select 
   year,
   Product_Segment,
   Count(*)  
from vw_product_segment_yearly
group by year,Product_Segment ;

###################################################################

create or replace view vw_product_segment_Summary as
select
    Year,
    Product_Segment,
    Count(Stockcode) As Products_Count,
    Sum(Total_Qty_Sold) as Qty_Sold,
    Sum(Total_Revenue) As Revenue,
    Sum(Total_Qty_Returned) As Qty_Returned,
    Sum(Total_Returns) AS Returns,
    round(Sum(Total_Returns) / Sum(Total_Revenue) ,2) As Return_Rate,
    Sum(Net_Revenue) AS Net_Revenue
From vw_product_segment_yearly
group by Year, Product_Segment;

select * from vw_product_segment_Summary;
##################################################################################################
# VW_Products_Status_Per_Customer

Create or replace view VW_Products_Status_Per_Customer As
with O As (
      select 
         CustomerID,
         StockCode,
         year(InvoiceDate) As Year,
         Sum(Quantity) Total_Quantities,
		 sum(Revenue) As Total_Revenue
	  From Fact_Orders
      where year(InvoiceDate) in (2010 , 2011)
      group by Year , CustomerID, StockCode
),
R As (
      select 
         CustomerID,
         StockCode,
         year(InvoiceDate) As Year,
         Sum(Quantity) As Returned_Quantities,
         Sum(Total_Amount) As Total_Returns
	  From fact_returns
      where year(InvoiceDate) in (2010 , 2011)
      group by Year, CustomerID, StockCode
),
RFM AS (
      select 
        CustomerID,
        RFM_Segment
	  From rfm_customer 
)

select 
   O.Year,
   O.CustomerID,
   RFM.RFM_Segment,
   O.StockCode,
   O.Total_Quantities,
   O.Total_Revenue,
   COALESCE(R.Returned_Quantities, 0) AS Returned_Quantities,
   COALESCE(R.Total_Returns, 0) AS Total_Returns,
   Round(COALESCE(R.Total_Returns, 0) / O.Total_Revenue  ,2) As Return_Rate,
   CASE
     WHEN R.Total_Returns > O.Total_Revenue * 1.5 THEN 'Critical'
     WHEN R.Total_Returns > O.Total_Revenue THEN 'High Risk'
     WHEN R.Total_Returns > O.Total_Revenue * 0.7 THEN 'Warning'
     ELSE 'Normal'
   END AS Risk_Level
From O
left join R
  on O.StockCode = R.StockCode
  And O.Year = R.Year
  And O.CustomerID = R.CustomerID
left join RFM
  on O.CustomerID = RFM.CustomerID
order by Year, Return_Rate desc ;


select * from VW_Products_Status_Per_Customer;
