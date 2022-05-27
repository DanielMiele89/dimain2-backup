CREATE Procedure [Staging].[SSRS_R0064_GBP60_Earning_Customers_v2] 
		@StartDate Date,
		@EndDate Date
As
--Declare @StartDate Date, @EndDate Date
--Set @StartDate = 'February 01, 2015'
--Set @EndDate = 'February 28, 2015'

if object_id('tempdb..#t1') is not null drop table #t1
Select	FanID,
		Sum(TotalCB) as TotalEarned,
		ROW_NUMBER() OVER(ORDER BY FanID ASC) AS RowNo
into #t1
from
(
	select	FanID,
			Sum(CashbackEarned) as TotalCB 
	from Relational.PartnerTrans as pt
	Where	AddedDate Between @StartDate and @EndDate
	Group by FanID
	Union All
	select	FanID,
			Sum(CashbackEarned) as TotalCB 
	from Relational.AdditionalCashbackAward as pt
	Where	AddedDate Between @StartDate and @EndDate
	Group by FanID
) as a
Group by FanID
	Having Sum(TotalCB) >=60
Order by FanID


Select	c.SourceUID as CIN,
		PartnerName,
		AddedDate,
		TransactionDate,
		TransactionAmount,
		pt.CashbackEarned,
		pt.CashbackEarned/TransactionAmount as CashbackRate,
		t.RowNo
from Warehouse.relational.PartnerTrans as pt
inner join #t1 as t
	on	pt.Fanid = t.fanid
INNER JOIN Warehouse.Relational.Customer c
	ON t.FanID = c.FanID
inner join warehouse.Relational.Partner as p
	on pt.PartnerID = p.PartnerID
Where AddedDate between @StartDate and @EndDate
Union All
Select	c.SourceUID as CIN,
		act.Description as PartnerName,
		--PartnerName,
		AddedDate,
		TranDate as TransactionDate,
		Amount as TransactionAmount,
		pt.CashbackEarned,
		pt.CashbackEarned/Amount as CashbackRate,
		t.RowNo
from Warehouse.relational.AdditionalCashbackAward as pt
inner join #t1 as t
	on	pt.Fanid = t.fanid
INNER JOIN Warehouse.Relational.Customer c
	ON t.FanID = c.FanID
inner join Warehouse.relational.AdditionalCashbackAwardType as act
	on pt.AdditionalCashbackAwardTypeID = act.AdditionalCashbackAwardTypeID
Where TranDate Between @StartDate and @EndDate
Order by t.RowNo,c.SourceUID,TransactionDate