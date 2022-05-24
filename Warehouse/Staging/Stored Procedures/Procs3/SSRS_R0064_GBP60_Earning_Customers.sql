Create Procedure Staging.SSRS_R0064_GBP60_Earning_Customers 
		@StartDate Date,
		@EndDate Date
as

IF OBJECT_ID ('tempdb..#t1') IS NOT NULL DROP TABLE #t1
Select FanID,Sum(CashbackEarned) as CashbackEarned
into #t1
from Warehouse.relational.PartnerTrans as pt
Where AddedDate between @StartDate and @EndDate
Group By FanID
HAVING SUm(CashbackEarned) >= 60
Order by Sum(CashbackEarned) Desc


Select	c.SourceUID as CIN,
		PartnerName,
		AddedDate,
		TransactionDate,
		TransactionAmount,
		pt.CashbackEarned,
		pt.CashbackEarned/TransactionAmount as CashbackRate
from Warehouse.relational.PartnerTrans as pt
inner join #t1 as t
	on	pt.Fanid = t.fanid and
		t.CashbackEarned >= 60
INNER JOIN Warehouse.Relational.Customer c
	ON t.FanID = c.FanID
inner join warehouse.Relational.Partner as p
	on pt.PartnerID = p.PartnerID
Where AddedDate between @StartDate and @EndDate
Order by c.SourceUID,TransactionDate