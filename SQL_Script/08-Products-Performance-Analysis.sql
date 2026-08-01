##################################################################################################
## "Products Performance Analysis" ##

## Top Product Generated Revenue

with Orders As (
            select 
				StockCode,
                Sum(Quantity) As Total_Quantities_Sold,
                Sum(Revenue) As Total_Sales
			From Fact_Orders
            where StockCode <> 11111
            group by StockCode ),
Returns_ As (
            select 
                StockCode,
                Sum(Quantity) As Total_Returned_Quantities,
                Sum(Total_Amount) As Total_returns
			From Fact_Returns
            where StockCode <> 11111
            group by StockCode ),
Adgustments As (
            select 
                StockCode,
                Sum(Quantity) As Total_Adjusted_Quantities,
                Sum(Total_Amount) As Total_Adjusted
			From Fact_Adjustments
            where StockCode <> 11111
            group by StockCode )

select 
     O.StockCode,
     O.Total_Quantities_Sold,
     O.Total_Sales,
     Round( O.Total_Sales / Sum(O.Total_Sales)over() *100 ,2) As Percentage_Of_Revenue,
     O.Total_Sales - coalesce( R.Total_returns ,0) - coalesce( A.Total_Adjusted ,0) As Net_Revenue
From Orders O
left join Returns_ R  
      On O.StockCode = R.StockCode
left join Adgustments A
      On O.StockCode = A.StockCode
order By O.Total_Sales desc
limit 25 ;


################################################################################
## Top Product Sales By quantity

with Orders As (
            select 
				StockCode,
                Sum(Quantity) As Total_Quantities_Sold,
                Sum(Revenue) As Total_Sales
			From Fact_Orders
            where StockCode <> 11111
            group by StockCode ),
Returns_ As (
            select 
                StockCode,
                Sum(Quantity) As Total_Returned_Quantities,
                Sum(Total_Amount) As Total_returns
			From Fact_Returns
            where StockCode <> 11111
            group by StockCode ),
Adgustments As (
            select 
                StockCode,
                Sum(Quantity) As Total_Adjusted_Quantities,
                Sum(Total_Amount) As Total_Adjusted
			From Fact_Adjustments
            where StockCode <> 11111
            group by StockCode )

select 
     O.StockCode,
     O.Total_Quantities_Sold,
     O.Total_Sales,
     Round( O.Total_Sales / Sum(O.Total_Sales)over() *100 ,2) As Percentage_Of_Revenue,
     O.Total_Sales - coalesce( R.Total_returns ,0) - coalesce( A.Total_Adjusted ,0) As Net_Revenue
From Orders O
left join Returns_ R  
      On O.StockCode = R.StockCode
left join Adgustments A
      On O.StockCode = A.StockCode
order By O.Total_Quantities_Sold desc
limit 25 ;


################################################################################
## Top Product achives High Return Rate
	
with Orders As (
            select 
				StockCode,
                Sum(Quantity) As Total_Quantities_Sold,
                Sum(Revenue) As Total_Sales
			From Fact_Orders
            where StockCode <> 11111
            group by StockCode ),
Returns_ As (
            select 
                StockCode,
                Sum(Quantity) As Total_Returned_Quantities,
                Sum(Total_Amount) As Total_returns
			From Fact_Returns
            where StockCode <> 11111
            group by StockCode ),
Adgustments As (
            select 
                StockCode,
                Sum(Quantity) As Total_Adjusted_Quantities,
                Sum(Total_Amount) As Total_Adjusted
			From Fact_Adjustments
            where StockCode <> 11111
            group by StockCode )

select 
     O.StockCode,
     R.Total_Returned_Quantities,
     coalesce( R.Total_returns ,0) As Total_returns,
     Round( coalesce( R.Total_returns ,0) / Sum(O.Total_Sales)over() *100 ,2) As Return_Rate,
     O.Total_Sales - coalesce( R.Total_returns ,0) - coalesce( A.Total_Adjusted ,0) As Net_Revenue
From Orders O
left join Returns_ R  
      On O.StockCode = R.StockCode
left join Adgustments A
      On O.StockCode = A.StockCode
order By Return_Rate desc
limit 25 ;


#  select * from Fact_Orders where StockCode in ( 84016 , 23843 )     
# StockCode    Total_Sales    Percentage_Of_Revenue    Net_Revenue   
#  84016        896933.15          4.24	             -140334.52
#  23843        168469.60          0.80                 0.00


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


#     Round( coalesce( R.Total_returns ,0) / Sum(O.Total_Sales)over() *100 ,3) As Return_Rate




################################################################################################################
## High Risk Product
# ----$$$-----  Very Dangerous  ---$$$-----
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
	 Round( coalesce( R.Total_returns ,0) / nullif( O.Total_Sales ,0)  *100 ,3) As Return_Rate,
     Round( coalesce( R.Total_returns ,0) / Sum(R.Total_returns)over(partition by O.Year,O.Quarter ) *100 ,3) As Percentage_Of_Returns,
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
where Round( coalesce( R.Total_returns ,0) / O.Total_Sales  *100 ,3) > 25
      And O.Total_Sales > 5000 
order By O.Year,O.Quarter, Return_Rate  desc ;



###########################################################################
# Extreme Return Impact Products
# ----$$$-----  Very Very Dangerous  ---$$$-----
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
	 Round( coalesce( R.Total_returns ,0) / nullif( O.Total_Sales ,0)  *100 ,3) As Return_Rate,
     Round( coalesce( R.Total_returns ,0) / Sum(R.Total_returns)over(partition by O.Year,O.Quarter ) *100 ,3) As Percentage_Of_Returns,
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
where  O.Total_Sales < coalesce( R.Total_returns ,0) 
      Or  O.Total_Sales - coalesce( R.Total_returns ,0) - coalesce( A.Total_Adjusted ,0) < 0
order By O.Year,O.Quarter, Return_Rate  desc ;

