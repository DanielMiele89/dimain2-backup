

--=====================================================================
--SP Name : [dbo].[CBP_Process_CustomerLapsing]
--Description: Calculate the Lapsing Status.
-- Update Log
--		Stuart - Unknown - Created
--		Ed - Unknown - integrated with other related SPs
--		Nitin - 02/09/2014 - Replaced ##cust table with dbo.FanSFDDailyUploadDataStaging
--=====================================================================
CREATE PROCEDURE [dbo].[__CBP_Process_CustomerLapsing]
	@RowNo int,
	@Interval Int,
	@EndDate date
AS
BEGIN	
	SET NOCOUNT ON
	
	--/*--------------------------------------------------------------------------------------------
	-------------------------------------Create Dates Table-----------------------------------------
	------------------------------------------------------------------------------------------------
	--Create a table which has the four quarterly date ranges to be used for calculating spend*/
	--Declare @LastDayPlusOne date,@Loop int
	--set datefirst 1
	----set @LastDayPlusOne = dateadd(dd, - 1 * (datepart(dw, GETDATE()) - 1) , GETDATE())
	--set @LastDayPlusOne = dateadd(dd, - 1 * (datepart(dw, @EndDate) - 1) , @EndDate)  -- Set to the beginning of thew 

	--DECLARE @Dates TABLE (StartDate DATE,EndDate DATE)
	--Set @Loop = 1
	--While @Loop <=4 
	--Begin
	--	Insert into @Dates
	--	Select	Dateadd(Month,-3*@Loop,@LastDayPlusOne) as StartDate,
	--			Dateadd(day,-1,Dateadd(Month,-3*(@Loop-1),@LastDayPlusOne)) as EndDate
	--	Set @Loop = @Loop+1
	--End


	--/*--------------------------------------------------------------------------------------------
	-------------------------------------Add row number to dates table------------------------------
	------------------------------------------------------------------------------------------------

	--Add row number to this to be used for comparisons later*/

	--DECLARE @DateRanges TABLE (StartDate DATE,EndDate DATE, RowNumber INT)
	--INSERT INTO @DateRanges(StartDate, EndDate, RowNumber)
	--SELECT *, RowNumber = ROW_NUMBER() OVER(ORDER BY StartDate ASC)	FROM @Dates

	-- -- Drop table as no longer needed
	--/*--------------------------------------------------------------------------------------------
	----------------------------------------------Pull TranStats------------------------------------
	------------------------------------------------------------------------------------------------
	--Create table of transaction spend per quarter per customer*/
	--Select	cb.FanID,
	--		dr.RowNumber as Qtr,
	--		SUM(Amount) as TotalSpend,
	--		Cast(COUNT(1) as real) as TranCount
	--Into #TranStats
	--from FanSFDDailyUploadDataStaging as cb
	--inner join dbo.trans as t with (nolock)
	--	on cb.FanID = t.FanID
	--inner join dbo.TransactionType as tt with (nolock)
	--	on t.TypeID = tt.ID
	--inner join dbo.Match as m with (nolock)
	--	on t.MatchID = m.ID
	--Inner join @DateRanges as dr
	--	on t.Date between StartDate and EndDate
	--Where m.Status = 1 and m.RewardStatus =1
	  
	--Group by cb.FanID,dr.RowNumber

	--Order by FanID

	------------------------------------------------------------------------------------------------
	----------------------Create a list of the possible rows of Qtrs and Customers------------------
	------------------------------------------------------------------------------------------------
	--Select cb.FanID,dr.RowNumber 
	--Into #Poss
	--From FanSFDDailyUploadDataStaging as cb, @DateRanges as dr

	--Create Clustered index ixc_p on #Poss(FanID)
	------------------------------------------------------------------------------------------------
	------------------Populate missing rows into #TranStats where no spend has occured--------------
	------------------------------------------------------------------------------------------------

	--Insert into #TranStats
	--select	p.FanID,
	--		p.RowNumber as Qtr,
	--		0 as TotalSpend,
	--		0 as TranCount
	--from #Poss as p
	--left outer join #TranStats as ts
	--	on	p.FanID = ts.FanID and
	--		p.RowNumber = ts.Qtr
	--Where ts.FanID is null		
	------------------------------------------------------------------------------------------------
	---------------------------------Drop table #Poss to save space---------------------------------
	------------------------------------------------------------------------------------------------
	--Drop table #Poss -- table no longer needed
	------------------------------------------------------------------------------------------------
	-----------------------Calculate Standard Deviations and add to #TranStats----------------------
	------------------------------------------------------------------------------------------------
	--Insert Into #TranStats
	--Select	FanID,
	--		0 AS qtr,
	--		STDEVP(TotalSpend) as TotalSpend,
	--		STDEVP(Cast(TranCount as real)) as TranCount 
	--from #TranStats 
	--Group by FanID

	--Create Clustered index ixc_TS on #TranStats(FanID)
	------------------------------------------------------------------------------------------------
	-----------------------------------------Pivot #TranStats---------------------------------------
	------------------------------------------------------------------------------------------------
	--Select	FanID,
	--		Sum(Case
	--				When Qtr = 1 then TotalSpend
	--				Else 0
	--			End) SpendQtr1,
	--		Sum(Case
	--				When Qtr = 1 then TranCount
	--				Else 0
	--			End) TranxQtr1,
	--		Sum(Case
	--				When Qtr = 2 then TotalSpend
	--				Else 0
	--			End) SpendQtr2,
	--		Sum(Case
	--				When Qtr = 2 then TranCount
	--				Else 0
	--			End) TranxQtr2,
	--		Sum(Case
	--				When Qtr = 3 then TotalSpend
	--				Else 0
	--			End) SpendQtr3,
	--		Sum(Case
	--				When Qtr = 3 then TranCount
	--				Else 0
	--			End) TranxQtr3,
	--		Sum(Case
	--				When Qtr = 4 then TotalSpend
	--				Else 0
	--			End) SpendQtr4,
	--		Sum(Case
	--				When Qtr = 4 then TranCount
	--				Else 0
	--			End) TranxQtr4,		
	--		Sum(Case
	--				When Qtr = 0 then TotalSpend
	--				Else 0
	--			End) SpendStDev,
	--		Sum(Case
	--				When Qtr = 0 then TranCount
	--				Else 0
	--			End) TranxStDev	
	--into #TranStatsPivoted
	--from #TranStats
	--Group by FanID

	--Create Clustered index ixc_TSP on #TranStatsPivoted(FanID)
	------------------------------------------------------------------------------------------------
	-----------------------------------------Drop TransStats to free up space-----------------------
	------------------------------------------------------------------------------------------------ 
	--Drop table #TranStats
	------------------------------------------------------------------------------------------------
	-----------------------------------------Lapsing Calculation------------------------------------
	------------------------------------------------------------------------------------------------
	--Select  cb.FanID,
	--		cb.ActivatedDate,
	--		Case
	--			When ActivatedDate > Cast(dateadd(Year,-1,GETDATE()) AS Date) then 'Not Lapsed'
	--			When tsp.SpendQtr4 <= 0 then 'Lapsed'
	--			When tsp.TranxQtr4 <  (tsp.TranxQtr3 - tsp.TranxStDev) and tsp.SpendQtr4 < (tsp.SpendQtr3 - tsp.SpendStDev) then 'Lapsed'
	--			When tsp.TranxQtr4 <  tsp.TranxQtr3 and tsp.SpendQtr4 < tsp.SpendQtr3 and
	--				 tsp.TranxQtr3 <  tsp.TranxQtr2 and tsp.SpendQtr3 < tsp.SpendQtr2 and
	--				 tsp.TranxQtr2 <  tsp.TranxQtr1 and tsp.SpendQtr2 < tsp.SpendQtr1 and
	--				 tsp.TranxQtr4 <  (tsp.TranxQtr1 - tsp.TranxStDev) and tsp.SpendQtr4 < (tsp.SpendQtr1 - tsp.SpendStDev) then 'Lapsed'
	--			Else 'Not Lapsed'
	--		End as LapsFlag
	--Into #Lapsing	
	--from FanSFDDailyUploadDataStaging as cb
	--inner join #TranStatsPivoted as tsp
	--	on cb.FanID = tsp.FanID
	--Order by LapsFlag

	--Create Clustered index ixc_Lap on #Lapsing(FanID)



	----------------------------------------------------------------------------------------------
	---------------------------------------Lapsing Calculation------------------------------------
	----------------------------------------------------------------------------------------------
	insert into CustomerLapse (FanID, LapsFlag, Date)
	Select	FanID,
			'Not Lapsed' as LapsFlag,
			Cast(CONVERT(varchar,@EndDate,107) as date) as [Date]
	from dbo.FanSFDDailyUploadDataStaging AS F

	--DROP TABLE #Lapsing,#TranStatsPivoted
END


--dbo.FanSFDDailyUploadDataStaging AS F