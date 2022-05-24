Create Procedure [Staging].[SSRS_R0063_BP_TopEarners_TopSpenders] 
			@StartDate Date,
			@EndDate Date, 
			@LaunchDate Date
As
--Declare @StartDate date, @EndDate Date, @LaunchDate Date
--Set @StartDate = 'Jan 01, 2015'
--Set @EndDate = 'Jan 31, 2015'
--Set @LaunchDate = 'Aug 08, 2013'


Select Top 15 
		*,
		ROW_NUMBER() OVER (ORDER BY Earned1 Desc) AS RowNumber1
Into #BP1
from
( 
select	SourceUID as CIN1,
		c.FanID as FanID1,
		Sum(TransactionAmount) as Spend1,
		Sum(CashbackEarned) as Earned1,
		Sum(CashbackEarned)/Sum(TransactionAmount) as CashbackRate1,
		Count(*) as Transactions1
from warehouse.relational.partnertrans as pt
inner join warehouse.relational.customer as c
	on pt.Fanid = c.FaniD
where partnerid = 3960 and TransactionDate between @StartDate and @EndDate
Group By c.FanID,SourceUID
) as a


select	Top 15
		*,
		ROW_NUMBER() OVER (ORDER BY Spend2 Desc) AS RowNumber2
Into #bp2
From
(
Select 
		SourceUID as CIN2,
		c.FanID as FanID2,
		Sum(TransactionAmount) as Spend2,
		Sum(CashbackEarned) as Earned2,
		Sum(CashbackEarned)/Sum(TransactionAmount) as CashbackRate2,
		Count(*) as Transactions2
from warehouse.relational.partnertrans as pt
inner join warehouse.relational.customer as c
	on pt.Fanid = c.FaniD
where partnerid = 3960 and TransactionDate between @StartDate and @EndDate
Group By c.FanID,SourceUID
) as a

-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------
select	Top 15
		*,
		ROW_NUMBER() OVER (ORDER BY Earned3 Desc) AS RowNumber3
Into #bp3
From
(
Select	SourceUID as CIN3,
		c.FanID as FanID3,
		c.ActivatedDate as ActivatedDate3,
		Sum(TransactionAmount) as Spend3,
		Sum(TransactionAmount) / Count(*) as AverageTransValue3,
		Sum(CashbackEarned) as Earned3,
		Sum(CashbackEarned)/Sum(TransactionAmount) as CashbackRate3,
		Count(*) as Transactions3
from warehouse.relational.partnertrans as pt
inner join warehouse.relational.customer as c
	on pt.Fanid = c.FaniD
where	partnerid = 3960 and 
		TransactionDate >= @LaunchDate and TransactionDate <= @EndDate
Group By c.FanID,SourceUID,c.ActivatedDate
) as a


select	Top 15
		*,
		ROW_NUMBER() OVER (ORDER BY Spend4 Desc) AS RowNumber4
Into #bp4
From
(
Select	SourceUID as CIN4,
		c.FanID as FanID4,
		c.ActivatedDate as ActivatedDate4,
		Sum(TransactionAmount) as Spend4,
		Sum(TransactionAmount) / Count(*) as AverageTransValue4,
		Sum(CashbackEarned) as Earned4,
		Sum(CashbackEarned)/Sum(TransactionAmount) as CashbackRate4,
		Count(*) as Transactions4
from warehouse.relational.partnertrans as pt
inner join warehouse.relational.customer as c
	on pt.Fanid = c.FaniD
where	partnerid = 3960 and 
		TransactionDate >= @LaunchDate and TransactionDate <= @EndDate
Group By c.FanID,SourceUID,c.ActivatedDate
) as a

Select * 
from #bp1 as [1]
inner join #bp2 as [2]
	on [1].RowNumber1 = [2].RowNumber2
inner join #bp3 as [3]
	on [1].RowNumber1 = [3].RowNumber3
inner join #bp4 as [4]
	on [1].RowNumber1 = [4].RowNumber4