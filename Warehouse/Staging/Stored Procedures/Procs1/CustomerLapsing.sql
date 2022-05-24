/*------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------

Author:		Stuart Barnley
Date:		20th June 2013

Objective:	Calculate the Lapsing Status

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------*/
CREATE Procedure [Staging].[CustomerLapsing]
					@EndDate date,
					@TableName nvarchar(150)
as
Begin	
/*--------------------------------------------------------------------------------------------
----------------------------------Create Customer Base----------------------------------------
----------------------------------------------------------------------------------------------
Create Customer base of customers who were activated at some point*/
if object_id('tempdb..#CustomerBase') is not null drop table #CustomerBase
select FanID, ActivatedDate
into #CustomerBase
from warehouse.relational.Customer 
where Activated = 1
--Add Primary Key
ALTER TABLE #CustomerBase
 ADD PRIMARY KEY (FanID)
/*--------------------------------------------------------------------------------------------
-----------------------------------Create Dates Table-----------------------------------------
----------------------------------------------------------------------------------------------
Create a table which has the four quarterly date ranges to be used for calculating spend*/
Declare @LastDayPlusOne date,@Loop int
set datefirst 1
--set @LastDayPlusOne = dateadd(dd, - 1 * (datepart(dw, GETDATE()) - 1) , GETDATE())
set @LastDayPlusOne = dateadd(dd, - 1 * (datepart(dw, @EndDate) - 1) , @EndDate)  -- Set to the beginning of thew 

if object_id('tempdb..#Dates') is not null drop table #Dates
Create Table #Dates (StartDate date,EndDate date)
Set @Loop = 1
While @Loop <=4 
Begin
	Insert into #Dates
	Select	Dateadd(Month,-3*@Loop,@LastDayPlusOne) as StartDate,
			Dateadd(day,-1,Dateadd(Month,-3*(@Loop-1),@LastDayPlusOne)) as EndDate
	Set @Loop = @Loop+1
End
/*--------------------------------------------------------------------------------------------
-----------------------------------Add row number to dates table------------------------------
----------------------------------------------------------------------------------------------
Add row number to this to be used for comparisons later*/
if object_id('tempdb..#DateRanges') is not null drop table #DateRanges
Select *,RowNumber = ROW_NUMBER() OVER(ORDER BY StartDate Asc) 
into #DateRanges
From #Dates

Drop table #Dates -- Drop table as no longer needed
/*--------------------------------------------------------------------------------------------
--------------------------------------------Pull TranStats------------------------------------
----------------------------------------------------------------------------------------------
Create table of transaction spend per quarter per customer*/

if object_id('tempdb..#TranStats') is not null drop table #TranStats
Select	cb.FanID,
		dr.RowNumber as Qtr,
		SUM(TransactionAmount) as TotalSpend,
		Cast(COUNT(1) as real) as TranCount
Into #TranStats
from #CustomerBase as cb
inner join warehouse.relational.PartnerTrans as pt
	on cb.FanID = pt.FanID
Inner join #DateRanges as dr
	on pt.TransactionDate between StartDate and EndDate
Group by cb.FanID,dr.RowNumber

Order by FanID
----------------------------------------------------------------------------------------------
--------------------Create a list of the possible rows of Qtrs and Customers------------------
----------------------------------------------------------------------------------------------
if object_id('tempdb..#Poss') is not null drop table #Poss
Select cb.FanID,dr.RowNumber 
Into #Poss
From #CustomerBase as cb, #DateRanges as dr
----------------------------------------------------------------------------------------------
----------------Populate missing rows into #TranStats where no spend has occured--------------
----------------------------------------------------------------------------------------------

Insert into #TranStats
select	p.FanID,
		p.RowNumber as Qtr,
		0 as TotalSpend,
		0 as TranCount
from #Poss as p
left outer join #TranStats as ts
	on	p.FanID = ts.FanID and
		p.RowNumber = ts.Qtr
Where ts.FanID is null		
----------------------------------------------------------------------------------------------
-------------------------------Drop table #Poss to save space---------------------------------
----------------------------------------------------------------------------------------------
Drop table #Poss -- table no longer needed
----------------------------------------------------------------------------------------------
---------------------Calculate Standard Deviations and add to #TranStats----------------------
----------------------------------------------------------------------------------------------
Insert Into #TranStats
Select	FanID,
		0 AS qtr,
		STDEVP(TotalSpend) as TotalSpend,
		STDEVP(Cast(TranCount as real)) as TranCount 
from #TranStats 
Group by FanID
----------------------------------------------------------------------------------------------
---------------------------------------Pivot #TranStats---------------------------------------
----------------------------------------------------------------------------------------------
if object_id('tempdb..#TranStatsPivoted') is not null drop table #TranStatsPivoted
Select	FanID,
		Sum(Case
				When Qtr = 1 then TotalSpend
				Else 0
			End) SpendQtr1,
		Sum(Case
				When Qtr = 1 then TranCount
				Else 0
			End) TranxQtr1,
		Sum(Case
				When Qtr = 2 then TotalSpend
				Else 0
			End) SpendQtr2,
		Sum(Case
				When Qtr = 2 then TranCount
				Else 0
			End) TranxQtr2,
		Sum(Case
				When Qtr = 3 then TotalSpend
				Else 0
			End) SpendQtr3,
		Sum(Case
				When Qtr = 3 then TranCount
				Else 0
			End) TranxQtr3,
		Sum(Case
				When Qtr = 4 then TotalSpend
				Else 0
			End) SpendQtr4,
		Sum(Case
				When Qtr = 4 then TranCount
				Else 0
			End) TranxQtr4,		
		Sum(Case
				When Qtr = 0 then TotalSpend
				Else 0
			End) SpendStDev,
		Sum(Case
				When Qtr = 0 then TranCount
				Else 0
			End) TranxStDev	
into #TranStatsPivoted
from #TranStats
Group by FanID

ALTER TABLE #TranStatsPivoted
 ADD PRIMARY KEY (FanID)
----------------------------------------------------------------------------------------------
---------------------------------------Drop TransStats to free up space-----------------------
---------------------------------------------------------------------------------------------- 
Drop table #TranStats
----------------------------------------------------------------------------------------------
---------------------------------------Lapsing Calculation------------------------------------
----------------------------------------------------------------------------------------------
if object_id('tempdb..#Lapsing') is not null drop table #Lapsing
Select  cb.FanID,
		cb.ActivatedDate,
		Case
			When ActivatedDate > Cast(dateadd(Year,-1,GETDATE()) AS Date) then 'Not Lapsed'
			When tsp.SpendQtr4 <= 0 then 'Lapsed'
			When tsp.TranxQtr4 <  (tsp.TranxQtr3 - tsp.TranxStDev) and tsp.SpendQtr4 < (tsp.SpendQtr3 - tsp.SpendStDev) then 'Lapsed'
			When tsp.TranxQtr4 <  tsp.TranxQtr3 and tsp.SpendQtr4 < tsp.SpendQtr3 and
				 tsp.TranxQtr3 <  tsp.TranxQtr2 and tsp.SpendQtr3 < tsp.SpendQtr2 and
				 tsp.TranxQtr2 <  tsp.TranxQtr1 and tsp.SpendQtr2 < tsp.SpendQtr1 and
				 tsp.TranxQtr4 <  (tsp.TranxQtr1 - tsp.TranxStDev) and tsp.SpendQtr4 < (tsp.SpendQtr1 - tsp.SpendStDev) then 'Lapsed'
			Else 'Not Lapsed'
		End as LapsFlag
Into #Lapsing	
from #CustomerBase as cb
inner join #TranStatsPivoted as tsp
	on cb.FanID = tsp.FanID
Order by LapsFlag
----------------------------------------------------------------------------------------------
---------------------------------------Lapsing Calculation------------------------------------
----------------------------------------------------------------------------------------------
Declare @Qry nvarchar(max)
Set @Qry = 
'if object_id('''+@TableName+''') is not null drop table ' + @TableName + '
Select	FanID,
		LapsFlag,
		Cast('''+CONVERT(varchar,@EndDate,107)+''' as date) as [Date]
into ' + @TableName + '
from #Lapsing'
Exec sp_ExecuteSQL @Qry

End