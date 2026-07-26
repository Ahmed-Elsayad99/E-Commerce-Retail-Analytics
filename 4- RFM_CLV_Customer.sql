########################################################################################################
## Create "RFM" Table ##

create table RFM_Customer (
CustomerID bigint primary key,
Recency int,
Frequency int,
Monetary decimal(12,2) , 
R_Score int,
F_Score int,
M_Score int,
RFM_Segment varchar(50) 
);


#2011-12-09 

insert into RFM_Customer (CustomerID, Recency, Frequency, Monetary)
select 
   CustomerID,
   datediff('2011-12-09', max(InvoiceDate)),
   count(distinct Invoice),
   sum(Quantity * Price)
from raw
group by CustomerID;
   

with RFM_Stats as (
   select CustomerID,
		  CASE
		   WHEN Recency <= 30 THEN 5
           WHEN Recency <= 60 THEN 4
		   WHEN Recency <= 90 THEN 3
		   WHEN Recency <= 120 THEN 2
           ELSE 1
          END AS R_Score,
		  CASE
           WHEN Frequency >= 120 THEN 5   
           WHEN Frequency >= 60 THEN 4   
		   WHEN Frequency >= 30 THEN 3   
           WHEN Frequency >= 15 THEN 2    
		   ELSE 1
          END AS F_Score ,
		  CASE
           WHEN Monetary >= 200000 THEN 5
           WHEN Monetary >= 90000 THEN 4
           WHEN Monetary >= 40000 THEN 3
           WHEN Monetary >= 20000 THEN 2
           ELSE 1
          END AS M_Score
	from  RFM_Customer)
update RFM_Customer R
join RFM_Stats A
on R.CustomerID = A.CustomerID
set 
R.R_Score = A.R_Score ,
R.F_Score = A.F_Score ,
R.M_Score = A.M_Score ;


update RFM_Customer
set 
RFM_Segment = 
   Case 
     when R_Score >= 4 and F_Score >= 4 and M_Score >= 4  then 'VIP'
     when R_Score >= 4 and F_Score >= 3  then 'Loyal'
     when R_Score = 5 and F_Score = 1  then 'New'
     when R_Score <=3 and F_Score >= 3 and M_Score >= 3  then 'At_Risk'
     when R_Score = 1 and F_Score = 1 and M_Score <= 2   then 'Lost'
     else 'Regular'
	end
WHERE CustomerID <> 0;

UPDATE RFM_Customer
SET RFM_Segment = 'Unknown_Customer'
WHERE CustomerID = 0;
 
SELECT *
FROM RFM_Customer;


########################################################################################################
-- Create "CLV" Table 

create table CLV_Customer as
select 
	CustomerID, 
    sum(Quantity * Price) as Revenue,
    Case
       When CustomerID = 0 then 'Unknown_Customer'
       when sum(Quantity * Price) >= 90000 then 'High_CLV'
       when sum(Quantity * Price) >= 20000 then 'Medium_CLV'
       Else 'Low_CLV'
	End as CLV_Segment
from raw
group by CustomerID
order by Revenue desc;

-- Validation
select * from CLV_Customer;
select count(*) from CLV_Customer;
select CLV_Segment, count(customerID) 
from CLV_Customer
group by CLV_Segment;
########################################################################################################
## Create "RFM" with "CLV" TABLE ##

create table RFM_CLV_Customer as
select 
    rfm.CustomerID,
    rfm.RFM_Segment,
    clv.CLV_Segment,
    case 
       when rfm.CustomerID = 0 then 'Unknown_Customer'
	   when rfm.RFM_Segment = 'Vip' and clv.CLV_Segment = 'High_CLV' then 'Champions'
       when rfm.RFM_Segment in ('Vip','Loyal') and clv.CLV_Segment = 'Medium_CLV' then 'High_Loyalty'
       when rfm.RFM_Segment = 'At_Risk' and clv.CLV_Segment = 'High_CLV' then 'High_Value_At_Risk'
       when rfm.RFM_Segment = 'New' and clv.CLV_Segment in ('High_CLV','Medium_CLV') then 'Promising_New'
       when rfm.RFM_Segment = 'Lost' and clv.CLV_Segment = 'Low_CLV' then 'Low_Priority'
       else 'Regular'
	End as Customer_Value_Segment
from RFM_Customer rfm
join CLV_Customer clv
  on rfm.customerID = clv.customerID;

select Count(*) from RFM_CLV_Customer;
