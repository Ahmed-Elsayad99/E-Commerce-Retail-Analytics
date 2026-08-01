##################################################################################################
## "Returns Analysis" ##

###################################################################################
## Which customers generate high revenue but low net value? (High Returns Behavior)

with Orders As (
			select 
                CustomerID,
                Sum(Revenue) As Total_Revenue
			From Fact_Orders 
            where CustomerID <> 0
            group by customerID ),
   Returns_ As (
		    select 
                CustomerID,
                Sum(Total_Amount) As Total_Returns
			From Fact_Returns
            where CustomerID <> 0
            group by customerID ),
Adjustments As (
            select 
                CustomerID,
                Sum(Total_Amount) As Total_Adjustments
			From Fact_Adjustments
            where CustomerID <> 0
            group by customerID )

select 
     O.CustomerID,
     O.Total_Revenue,
     coalesce( R.Total_Returns,0) As Total_Returns,
     coalesce( A.Total_Adjustments,0) As Total_Adjustments,
     O.Total_Revenue - coalesce( R.Total_Returns,0) - coalesce( A.Total_Adjustments,0) As Net_Revenue,
     round( coalesce( R.Total_Returns,0) / O.Total_Revenue *100 , 2) as Return_Rate
from Orders O
left join Returns_ R     On O.customerID = R.customerID
left join Adjustments A  On O.customerID = A.customerID
where O.Total_Revenue >= 50000 
and 
( coalesce( R.Total_Returns,0) / O.Total_Revenue >= 0.30 
or 
O.Total_Revenue - coalesce( R.Total_Returns,0) - coalesce( A.Total_Adjustments,0) <=  O.Total_Revenue * 0.25 )
order by Return_Rate desc, Net_Revenue asc; 

### Vs RFM Segments 


#####################################################################
# Who is the most customer have high returns

with Orders As (
			select 
                CustomerID,
                Sum(Revenue) As Total_Revenue
			From Fact_Orders 
            where CustomerID <> 0
            group by customerID ),
   Returns_ As (
		    select 
                CustomerID,
                Sum(Total_Amount) As Total_Returns
			From Fact_Returns
            where CustomerID <> 0
            group by customerID ),
Adjustments As (
            select 
                CustomerID,
                Sum(Total_Amount) As Total_Adjustments
			From Fact_Adjustments
            where CustomerID <> 0
            group by customerID )

select 
     O.CustomerID,
     O.Total_Revenue,
     coalesce( R.Total_Returns,0) As Total_Returns,
     coalesce( A.Total_Adjustments,0) As Total_Adjustments,
     O.Total_Revenue - coalesce( R.Total_Returns,0) - coalesce( A.Total_Adjustments,0) As Net_Revenue,
     round( coalesce( R.Total_Returns,0) / O.Total_Revenue *100 , 2) as Return_Rate
from Orders O
left join Returns_ R     On O.customerID = R.customerID
left join Adjustments A  On O.customerID = A.customerID
order by Return_Rate desc , Net_Revenue asc; 


############################################################
## Return Impact Analysis By RFM Segments.
##  Which customer segments are most sensitive to returns?

with Orders As (
			select 
                CustomerID,
                Sum(Revenue) As Total_Revenue
			From Fact_Orders 
            where CustomerID <> 0
            group by customerID ),
   Returns_ As (
		    select 
                CustomerID,
                Sum(Total_Amount) As Total_Returns
			From Fact_Returns
            where CustomerID <> 0
            group by customerID ),
Adjustments As (
            select 
                CustomerID,
                Sum(Total_Amount) As Total_Adjustments
			From Fact_Adjustments
            where CustomerID <> 0
            group by customerID )

select 
     RFM.RFM_Segment,
     Count( O.CustomerID ) As Total_Customers,
     Sum(O.Total_Revenue) As Total_Revenue,
     coalesce(Sum( R.Total_Returns) ,0) As Total_Returns,
     coalesce(Sum( A.Total_Adjustments) ,0) As Total_Adjustments,
     Sum(O.Total_Revenue) - coalesce(Sum( R.Total_Returns) ,0) - coalesce( Sum( A.Total_Adjustments),0) As Net_Revenue,
     round( coalesce(Sum( R.Total_Returns) ,0) / Sum(coalesce(Sum( R.Total_Returns) ,0))Over() *100 ,2)
      as Percentage_Of_Returns ,
     round( coalesce(Sum( R.Total_Returns) ,0) / Sum(O.Total_Revenue) *100 , 2) as Return_Rate
from Orders O
left join Returns_ R             On O.customerID = R.customerID
left join Adjustments A          On O.customerID = A.customerID
left join RFM_CLV_Customer RFM   On O.customerID = RFM.customerID
group by RFM.RFM_Segment
order by Return_Rate desc ;


##################################################################################################
## # Repeat Customers × Returns Rate

with Returns_ As (
          select 
              CustomerID,
              Count(distinct Invoice) As Total_Orders,
              Sum(Total_Amount) As Total_Returns,
              case
                 when Count(distinct Invoice) > 1 then 'Repeat_customer'
                 else 'One_Time_Customer'
			  End As Customer_Type
		  from Fact_Returns
          Where CustomerID <> 0
          Group By CustomerID 
          having Count(distinct Invoice) > 1 )

select
    RFM.RFM_Segment,
    count( R.CustomerID ) As Total_Customers,
    Sum( R.Total_Returns ) As Total_Returns,
    round( Sum( R.Total_Returns ) / Sum(Sum( R.Total_Returns ))over() *100,2)
      As Percentage_Of_Returns
From RFM_CLV_Customer RFM 
join Returns_ R   On RFM.CustomerID = R.CustomerID
group by RFM.RFM_Segment ;


##################################################################################################
# # Lifecycle × Returns (مين بينزل بسبب المرتجعات)

with Returns_ As (
          select 
              CustomerID,
              year(InvoiceDate) As Year,
              quarter(InvoiceDate) As Quarter,
              Count(distinct Invoice) As Total_Orders,
              Sum(Total_Amount) As Total_Returns
		  from Fact_Returns
          Where CustomerID <> 0
          Group By CustomerID ,
				   year(InvoiceDate),
                   quarter(InvoiceDate)),
	Lifecysle As (
          select
              CustomerID,
              CAST(SUBSTRING(Prev_Quarter,1,4) AS UNSIGNED) AS Year,
              CAST(SUBSTRING(Prev_Quarter,7,1) AS UNSIGNED) AS Quarter,
              Prev_Quarter,
              Current_Quarter,
              Lifecycle_movement
		  From customer_lifecycle_transition 
          where CustomerID <> 0 )

select 
    L.Lifecycle_movement,
    Count(L.CustomerID) As Total_Customers,
    sum(R.Total_Returns) as total_Returns,
    Sum(R.Total_Orders) As Total_Orders,
    round(Avg( R.Total_Returns ) ) As Avg_Returns,
    round(Avg( R.Total_Orders ) ) As Avg_Orders,
    round( Sum(R.Total_Returns) / Sum(Sum(R.Total_Returns))over() *100 ,2) As Percentage_Of_Returns
from Lifecysle L 
join Returns_ R   
    On L.CustomerID = R.CustomerID 
group by L.Lifecycle_movement ;



###### By quarter And "" DowmWard ""


with Returns_ As (
          select 
              CustomerID,
              year(InvoiceDate) As Year,
              quarter(InvoiceDate) As Quarter,
              Count(distinct Invoice) As Total_Orders,
              Sum(Total_Amount) As Total_Returns
		  from Fact_Returns
          Where CustomerID <> 0
          Group By CustomerID ,
				   year(InvoiceDate),
                   quarter(InvoiceDate)),
	Lifecysle As (
          select
              CustomerID,
              CAST(SUBSTRING(Prev_Quarter,1,4) AS UNSIGNED) AS Year,
              CAST(SUBSTRING(Prev_Quarter,7,1) AS UNSIGNED) AS Quarter,
              Prev_Quarter,
              Current_Quarter,
              Lifecycle_movement
		  From customer_lifecycle_transition 
          where CustomerID <> 0 )

select 
    L.Prev_Quarter,
    L.Current_Quarter,
    L.Lifecycle_movement,
    Count(L.CustomerID) As Total_Customers,
    sum(R.Total_Returns) as total_Returns,
    Sum(R.Total_Orders) As Total_Orders,
    round(Avg( R.Total_Returns ) ) As Avg_Returns,
    round(Avg( R.Total_Orders ) ) As Avg_Orders,
    round( Sum(R.Total_Returns) / Sum(Sum(R.Total_Returns))over() *100 ,2) As Percentage_Of_Returns
from Lifecysle L 
join Returns_ R   
    On L.CustomerID = R.CustomerID 
	And L.Year = R.Year 
	And L.Quarter = R.Quarter
where Lifecycle_movement = 'DownWard'
group by L.Prev_Quarter ,L.Current_Quarter, L.Lifecycle_movement
order by L.Prev_Quarter ;



##################################################################################################
## Retention Impact Question (جامدة جدًا)  \\ If we retain the top risk customers, how much revenue can be protected?

with Orders as (
			select 
                CustomerID,
                year(InvoiceDate) As Year,
                quarter(InvoiceDate) As Quarter,
                Sum(Revenue) As Total_Revenue
			from Fact_Orders
            where CustomerID <> 0 
            group by 
				CustomerID,
				year(InvoiceDate),
                quarter(InvoiceDate) ),
   Return_ As (
		    select 
		        CustomerID,
                year(InvoiceDate) As Year,
                quarter(InvoiceDate) As Quarter,
                Sum(Total_Amount) As Total_Returns,
                Count(distinct Invoice) As Total_Orders
			from Fact_Returns
            where CustomerID <> 0 
            group by
                CustomerID,
                year(InvoiceDate),
                quarter(InvoiceDate) ),
 Lifecycle AS (
            select 
			    CustomerID,
                cast(substring(Prev_Quarter,1,4) as unsigned) as Year,
                cast(substring(Prev_Quarter,7,1) as unsigned) As Quarter,
				Prev_Quarter,
                Current_Quarter,
                Lifecycle_movement
			From customer_lifecycle_transition
            where CustomerID <> 0)

select
    Count(distinct L.CustomerID) As Total_Risk_Customers,
    Sum(O.Total_Revenue) As Total_Revenue ,
    sum(coalesce( R.Total_Returns ,0)) As Total_Returns,
    Sum(O.Total_Revenue) - sum(coalesce( R.Total_Returns ,0)) As Net_Protect_Revenue
from Lifecycle L
left join Orders O  
  on L.CustomerID = O.CustomerID
  And L.Year = O.Year
  And L.Quarter = O.Quarter
left join Return_ R 
  on L.CustomerID = R.CustomerID
  And L.Year = R.Year
  And L.Quarter = R.Quarter
  where  Lifecycle_movement = 'DownWard' ;

