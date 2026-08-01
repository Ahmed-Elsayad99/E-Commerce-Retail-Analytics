################################################################################
## Trend / Seasonal Product Analysis

with Orders As (
            select 
				StockCode,
                year(InvoiceDate) As Year,
                quarter(InvoiceDate) As Quarter,
                Sum(Quantity) As Total_Quantities_Sold,
                Sum(Revenue) As Total_Sales
			From Fact_Orders
            where StockCode <> 11111
            group by StockCode, Year, Quarter ),
Returns_ As (
            select 
                StockCode,
                year(InvoiceDate) As Year,
                quarter(InvoiceDate) As Quarter,
                Sum(Quantity) As Total_Returned_Quantities,
                Sum(Total_Amount) As Total_returns
			From Fact_Returns
            where StockCode <> 11111
            group by StockCode , Year, Quarter ),
Adgustments As (
            select 
                StockCode,
                year(InvoiceDate) As Year,
                quarter(InvoiceDate) As Quarter,
                Sum(Quantity) As Total_Adjusted_Quantities,
                Sum(Total_Amount) As Total_Adjusted
			From Fact_Adjustments
            where StockCode <> 11111
            group by StockCode , Year, Quarter )

select 
     O.StockCode,
     O.Year,
     O.Quarter,
     O.Total_Quantities_Sold,
     O.Total_Sales,
     coalesce( R.Total_Returned_Quantities ,0) As Total_Returned_Quantities,
     coalesce( R.Total_returns ,0) As Total_returns,
	 Round( coalesce( R.Total_returns ,0) / nullif(O.Total_Sales ,0)  *100 ,3) As Return_Rate,
     Round( coalesce( R.Total_returns ,0) / Sum(R.Total_returns)over(partition by O.Year,O.Quarter) *100 ,3) As Percentage_Of_Returns,
     O.Total_Sales - coalesce( R.Total_returns ,0) - coalesce( A.Total_Adjusted ,0) As Net_Revenue
From Orders O
left join Returns_ R  
      On O.StockCode = R.StockCode
      And O.Year = R.Year 
      And O.Quarter = R.Quarter
left join Adgustments A
      On O.StockCode = A.StockCode
      And O.Year = A.Year 
      And O.Quarter = A.Quarter
order By O.Year,O.Quarter, O.Total_Sales  desc ;


################################################################################################
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



#####################################################################################
#####################################################################################
## Customer Lifecycle Flow  \ How customers move across lifecycle stages quarter-over-quarter?

SELECT
    Prev_Quarter,
    Current_Quarter,
    Transition,
    COUNT(CustomerID) AS Total_Customers,
	ROUND( COUNT(CustomerID) / SUM(COUNT(CustomerID)) OVER (PARTITION BY Current_Quarter) * 100 ,2) AS Percent_of_Quarter
FROM Customer_Lifecycle_Transition
where Prev_Quarter is not null and Transition is not null and Current_Customer_Value <> Prev_Customer_Value
GROUP BY
    Prev_Quarter,
    Current_Quarter,
    Transition
ORDER BY
    Current_Quarter,
    Total_Customers desc;

#################################################################################
## MoM% By Revenue , Returns , Orders ##

with T As (
        select
            Year,
			Month,
            Total_Revenue,
            lag(Total_Revenue)Over(order by Year, Month ) As Prev_Revenue,
            Total_Returns,
            lag(Total_Returns)Over(order by Year, Month ) As Prev_Returns,
            Total_Orders,
            lag(Total_Orders)Over(order by Year, Month ) As Prev_Orders
		from Monthly_Kpis )
select 
    Year,
	Month,
	Total_Revenue,
    coalesce(round((Total_Revenue - Prev_Revenue) / nullif(Prev_Revenue,0) *100 ,2) ,0) As Revenue_MoM ,
    Total_Returns,
    coalesce(round((Total_Returns - Prev_Returns) / nullif(Prev_Returns,0) *100 ,2) ,0) As Returns_MoM ,
    Total_Orders,
    coalesce(round((Total_Orders - Prev_Orders) / nullif(Prev_Orders,0) *100 ,2) ,0) As Orders_MoM 
from t
order by Year, Month ;

########################################################################3
## َ QoQ % By Revenue , Returns , Orders ##

with T As (
        select
            Year,
			Quarter,
            Sum(Total_Revenue) As Total_Revenue,
            lag(Sum(Total_Revenue))Over(order by Year, Quarter ) As Prev_Revenue,
            Sum(Total_Returns) AS Total_Returns,
            lag(Sum(Total_Returns))Over(order by Year, Quarter ) As Prev_Returns,
            Sum(Total_Orders) AS Total_Orders,
            lag(Sum(Total_Orders))Over(order by Year, Quarter ) As Prev_Orders
		from Monthly_Kpis
        group by Year,Quarter )
select 
    Year,
	Quarter,
	Total_Revenue,
    coalesce(round((Total_Revenue - Prev_Revenue) / nullif(Prev_Revenue,0) *100 ,2) ,0) As Revenue_QoQ ,
    Total_Returns,
    coalesce(round((Total_Returns - Prev_Returns) / nullif(Prev_Returns,0) *100 ,2) ,0) As Returns_QoQ ,
    Total_Orders,
    coalesce(round((Total_Orders - Prev_Orders) / nullif(Prev_Orders,0) *100 ,2) ,0) As Orders_QoQ 
from t
order by Year, Quarter ;

########################################################################3
## َ YoY % By Revenue , Returns , Orders ##

with T As (
        select
            Year,
            Sum(Total_Revenue) As Total_Revenue,
            lag(Sum(Total_Revenue))Over(order by Year ) As Prev_Revenue,
            Sum(Total_Returns) AS Total_Returns,
            lag(Sum(Total_Returns))Over(order by Year ) As Prev_Returns,
            Sum(Total_Orders) AS Total_Orders,
            lag(Sum(Total_Orders))Over(order by Year) As Prev_Orders
		from Monthly_Kpis
        group by Year )
select 
    Year,
	Total_Revenue,
    coalesce(round((Total_Revenue - Prev_Revenue) / nullif(Prev_Revenue,0) *100 ,2) ,0) As Revenue_YoY ,
    Total_Returns,
    coalesce(round((Total_Returns - Prev_Returns) / nullif(Prev_Returns,0) *100 ,2) ,0) As Returns_YoY ,
    Total_Orders,
    coalesce(round((Total_Orders - Prev_Orders) / nullif(Prev_Orders,0) *100 ,2) ,0) As Orders_YoY 
from t
order by Year;

########################################################################3
## َ YoY % For ALL ##

with O As (
     select 
		year(invoiceDate) As Year,
        count(distinct CustomerID) As Total_Customers,
        count(distinct Invoice) As Orders,
        Sum(Revenue) AS Revenue
     From Fact_Orders
     where year(invoiceDate) <> 2009
     group by year(invoiceDate)
     order by Year
),
R As (
     select
        year(invoiceDate) As Year,
        count(distinct Invoice) As Returned_Orders,
        Sum(Quantity) As Returned_Quantities,
        sum(Total_Amount) As Total_Returns
	 From Fact_Returns
     where year(invoiceDate) <> 2009
     group by year(invoiceDate)
     order by Year
),
A As (
     select 
        year(invoiceDate) As Year,
        Sum(Total_Amount) As Total_Adjustments
	 From fact_adjustments
     where year(invoiceDate) <> 2009
     group by year(invoiceDate)
     order by Year
)
select 
   O.Year,
   O.Total_Customers,
   coalesce(round((O.Total_Customers - lag(O.Total_Customers)over(order by O.Year)) / lag(O.Total_Customers)over(order by O.Year) *100 ,2) ,0) As Customer_YoY,
   O.Orders,
   coalesce(round((O.Orders - lag(O.Orders)over(order by O.Year)) / lag(O.Orders)over(order by O.Year) *100 ,2) ,0) As Orders_YoY,
   O.Revenue,
   coalesce(round((O.Revenue - lag(O.Revenue)over(order by O.Year)) / lag(O.Revenue)over(order by O.Year) *100 ,2) ,0) As Revenue_YoY,
   R.Returned_Orders,
   coalesce(round((R.Returned_Orders - lag(R.Returned_Orders)over(order by O.Year)) / lag(R.Returned_Orders)over(order by O.Year) *100 ,2) ,0) As Returned_Orders_YoY,
   R.Returned_Quantities,
   coalesce(round((R.Returned_Quantities - lag(R.Returned_Quantities)over(order by O.Year)) / lag(R.Returned_Quantities)over(order by O.Year) *100 ,2) ,0) As Returned_Quantities_YoY,
   R.Total_Returns,
   coalesce(round((R.Total_Returns - lag(R.Total_Returns)over(order by O.Year)) / lag(R.Total_Returns)over(order by O.Year) *100 ,2) ,0) As Total_Returns_YoY,
   O.Revenue - R.Total_Returns - A.Total_Adjustments As Net_Revenue,
   coalesce(round(((O.Revenue - R.Total_Returns - A.Total_Adjustments) - lag(O.Revenue - R.Total_Returns - A.Total_Adjustments)
   over(order by O.Year)) / lag(O.Revenue - R.Total_Returns - A.Total_Adjustments)over(order by O.Year) *100 ,2) ,0) As Net_Revenue_YoY,
   round( R.Total_Returns / O.Revenue *100 ,2) As Return_Rate,
   coalesce(round(((R.Total_Returns / O.Revenue *100) - lag(R.Total_Returns / O.Revenue *100)
   over(order by O.Year)) / lag(R.Total_Returns / O.Revenue *100)over(order by O.Year) *100 ,2) ,0) As Return_Rate_YoY
From O 
left join R  on O.Year = R.Year
left join A On O.Year = A.Year
order by O.Year ;
