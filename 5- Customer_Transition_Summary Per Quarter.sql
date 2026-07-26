-- create "RFM_Per_Quarter" 

create table RFM_Per_Quarter as
select 
  O.CustomerID,
  D.year as Year,
  D.quarter as Quarter,
  DATEDIFF(
    DATE(
        CASE
            WHEN d.quarter = 1 THEN CONCAT(d.year, '-03-31')
            WHEN d.quarter = 2 THEN CONCAT(d.year, '-06-30')
            WHEN d.quarter = 3 THEN CONCAT(d.year, '-09-30')
            WHEN d.quarter = 4 THEN CONCAT(d.year, '-12-31')
        END
    ),
    MAX(O.InvoiceDate)
) AS Recency,
    count(distinct O.Invoice ) as Frequency,
    Sum(O.Revenue) as Monetary

from Fact_ORders O
join Dim_Date D   on O.InvoiceDate = D.InvoiceDate
group by 
O.CustomerID,
D.year,
D.quarter;

alter table RFM_Per_Quarter
add R_Score bigint,
add F_Score bigint,
add M_Score bigint,
add RFM_Segment varchar(50);

-- SET SQL_SAFE_UPDATES = 0;

update RFM_Per_Quarter
set 
R_Score=
    case
      when Recency <= 10 then 5
      when Recency <= 20 then 4
      when Recency <= 30 then 3
      when Recency <= 60 then 2
      else 1
	end  ,
F_Score =
    case
      when Frequency >= 30 then 5
      when Frequency >= 20 then 4
      when Frequency >= 15 then 3
      when Frequency >= 8 then 2
      else 1
	end  ,
M_score = 
    case 
      when Monetary >= 40000 then 5
      when Monetary >= 20000 then 4
      when Monetary >= 10000 then 3
      when Monetary >= 1000 then 2
      else 1 
	end
;

update RFM_Per_Quarter
set RFM_Segment =
   case 
     when R_Score >= 4 and F_Score >= 4 and M_Score >= 4 then 'Vip'
     when R_Score >= 4 and F_Score >= 3  then 'Loyal'
     when R_Score = 5 and F_Score = 1  then 'New'
     when R_Score <= 2 and F_Score >= 3 and M_Score >= 3 then 'At_Risk'
     when R_Score = 1 and F_Score = 1 and M_Score <= 2 then 'Lost'
     else 'Regular'
   end ;

update RFM_Per_Quarter
set RFM_Segment = 'Unknown_Customer'
where CustomerID = 0 ;

-- SET SQL_SAFE_UPDATES = 1;


select * from RFM_Per_Quarter
where RFM_Segment = 'Unknown_Customer'
order by Year, Quarter;

select * from RFM_Per_Quarter
where RFM_Segment = 'Vip'
order by Year, Quarter;

##################################################################################################
-- create "CLV_Per_Quarter"

create table CLV_Per_Quarter as
select 
  O.CustomerID,
  D.year As Year,
  D.quarter as Quarter,
  sum(O.Revenue) as Revenue
  
from Fact_ORders O
join Dim_Date D   on O.InvoiceDate = D.InvoiceDate
group by 
O.CustomerID,
D.year,
D.quarter;

select * from CLV_Per_Quarter
where Quarter = 4 and CustomerID <> 0 and year = 2010
order by Revenue desc;

alter table CLV_Per_Quarter
add CLV_Segment varchar(50); 

update CLV_Per_Quarter
set CLV_Segment =
  case 
     when CustomerID = 0 then 'Unknown_Customer'
     when Revenue >= 20000 then 'High_CLV'
     when Revenue >= 5000 then 'Medium_CLV'
     else 'Low_CLV'
	end;


select * from CLV_Per_Quarter
where CLV_Segment = 'High_CLV'
order by year,quarter;


##################################################################################################
-- create "RFM_CLV_Per_Quarter"

create table RFM_CLV_Per_Quarter as 
select 
   R.CustomerID,
   R.Year,
   R.Quarter,
   R.RFM_Segment,
   C.CLV_Segment
from rfm_per_quarter R
join clv_per_quarter C 
  on  R.CustomerID = C.CustomerID
  And R.Year = C.Year
  And R.Quarter = C.Quarter;

alter table RFM_CLV_Per_Quarter
add Customer_Value varchar(100);

update RFM_CLV_Per_Quarter
set Customer_Value =
  case 
     when CustomerID = 0 then 'Unknown_Customer'
     when RFM_Segment = 'Vip' and CLV_Segment = 'High_CLV' then 'Champions'
     when RFM_Segment in ('Vip', 'Loyal') and CLV_Segment = 'Medium_CLV' then 'High_Loyalty'
     when RFM_Segment = 'At_Risk' and CLV_Segment = 'High_CLV' then 'High_Value_At_Risk'
     when RFM_Segment = 'New' and CLV_Segment in ('High_CLV', 'Medium_CLV') then 'Promising_New'
     when RFM_Segment = 'Lost' and CLV_Segment = 'Low_CLV' then 'Low_Priority'
     else 'Regular'
	end ;

select * from RFM_CLV_Per_Quarter
where year = 2010 and Quarter = 1 
order by Year , Quarter;


alter table rfm_clv_per_quarter
add Quarter_Key bigint ;
update rfm_clv_per_quarter
set Quarter_Key = concat(cast(substring(Quarter,1,4) as unsigned), 0 , cast(substring(Quarter,7,1) as unsigned) );


select * from rfm_clv_per_quarter;


########################################################################################################################
## CREATE TABLE "Customer_Lifecycle_Transition" ## 


create table Customer_Lifecycle_Transition as
	select *
    from (
		select 
        CustomerID,
        year,
        lag(Quarter)over(partition by CustomerID order by year, Quarter) as Prev_Quarter,
        Quarter as Quarter,
        lag(Customer_Value)over(partition by CustomerID order by year, Quarter) as Prev_Customer_Value,
        Customer_Value as Current_Customer_Value
	from rfm_clv_per_quarter ) A
order by   CustomerID,year, Quarter ;

alter table Customer_Lifecycle_Transition
add Transition  varchar(100) ;

update Customer_Lifecycle_Transition
set Transition = concat( Prev_Customer_Value , ' → ' , Current_Customer_Value );

update Customer_Lifecycle_Transition
set Transition = 'Unknown_Customer'
where CustomerID = 0 ;

update Customer_Lifecycle_Transition
set Transition = 'No_Value_Perv_Q'
where Transition is Null;

update Customer_Lifecycle_Transition
set Prev_Customer_Value = 'No_Value_Perv_Q'
where Prev_Customer_Value is Null;

alter table Customer_Lifecycle_Transition
add Lifecycle_movement varchar(50);

update Customer_Lifecycle_Transition
set Lifecycle_movement =
    case
        when
            case Prev_Customer_Value
                when 'Low_Priority' then 1
                when 'Promising_New' then 2
                when 'Regular' then 3
                when 'High_Value_At_Risk' then 4
                when 'High_Loyalty' then 5
                when 'Champions' then 6
            end
        >
            case Current_Customer_Value
                when 'Low_Priority' then 1
                when 'Promising_New' then 2
                when 'Regular' then 3
                when 'High_Value_At_Risk' then 4
                when 'High_Loyalty' then 5
                when 'Champions' then 6
            end
        then 'DownWard'

        when
            case Prev_Customer_Value
                when 'Low_Priority' then 1
                when 'Promising_New' then 2
                when 'Regular' then 3
                when 'High_Value_At_Risk' then 4
                when 'High_Loyalty' then 5
                when 'Champions' then 6
            end
        <
            case Current_Customer_Value
                when 'Low_Priority' then 1
                when 'Promising_New' then 2
                when 'Regular' then 3
                when 'High_Value_At_Risk' then 4
                when 'High_Loyalty' then 5
                when 'Champions' then 6
            end
        then 'UpWard'

        else 'Stable'
    end;

update Customer_Lifecycle_Transition
set Lifecycle_movement = 'Stable'
where Transition = 'No_Value_Perv_Q';

-- check table
select * from Customer_Lifecycle_Transition
where year = 2010 and quarter = 3
order by Year , Quarter;

select * from Customer_Lifecycle_Transition
where prev_Quarter is null
order by Year , Quarter;

select * from Customer_Lifecycle_Transition
where Lifecycle_movement = 'UpWard'
order by Year , Quarter;


##################################################################################################
-- CREATE table "" Customer_Transition_Summary ""

CREATE table Customer_Transition_Summary AS
SELECT
    year,
    Quarter,
    Lifecycle_movement,
    COUNT(CustomerID) AS Total_Customers,
	ROUND( COUNT(CustomerID) / SUM(COUNT(CustomerID)) OVER (PARTITION BY year,Quarter) * 100 ,2) AS Percent_of_Quarter
FROM Customer_Lifecycle_Transition
where Prev_Quarter <> 0 and Transition <> 'No_Value_Perv_Q'
GROUP BY
    year,
    Prev_Quarter,
    Quarter,
    Lifecycle_movement
ORDER BY
    year, Quarter,
    Total_Customers desc;

select * from  Customer_Transition_Summary ;


