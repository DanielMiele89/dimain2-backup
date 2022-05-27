
-- =============================================
-- Author: Code - Stuart Barnley SP Created by: Suraj Chahal
-- Create date: 03/09/2014
-- Description: Script to group Spend and Cashback Earned eligible customers together by how much they have earned
-- =============================================
CREATE PROCEDURE [Staging].[SSRS_R0048_SpendAndEarnForCashbackEligible]
				(@StartDate Date, 
				@EndDate Date)

AS
BEGIN
	SET NOCOUNT ON;

Declare @LaunchDate Date
Set @LaunchDate = 'Aug 08, 2013'


IF OBJECT_ID ('tempdb..#cb') IS NOT NULL DROP TABLE #cb
SELECT	c.FanID,
	CASE
		WHEN r.ReportFromDate IS NOT NULL THEN r.ReportFromDate
		ELSE c.ActivatedDate
	END AS ReportFromDate,
	r.AnalysisGroupL1,
	c.ActivatedDate
INTO #cb
FROM Warehouse.Relational.Customer as c
-----------Link to old Activated Customer base to pull POC non Seeds customers to avoid impact legacy data
LEFT OUTER JOIN Warehouse.InsightArchive.Customer_ReportBasePOC2_20130724 as IA
	ON	c.FanID = ia.Fanid and
		ia.Customer_Type = 'A'
LEFT OUTER JOIN Relational.ReportBaseMay2012 as r
	ON	ia.FanID = r.FanID
where	Activated = 1 and 
	(ActivatedDate >= @LaunchDate or r.Fanid is not null)
	 and	
	(ActivatedDate <= @EndDate or ia.fanid is not null)

CREATE CLUSTERED INDEX ixc_cb on #cb(FanID)
--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
Select	cb.FanID,
		pt.TransactionAmount,
		pt.CashbackEarned,
		pt.AddedDate,
		PartnerID
INTO #Trans
from #CB as cb
inner join warehouse.relational.partnertrans as pt
	on cb.FanID = pt.FanID
Where	pt.TransactionDate >= cb.ReportFromDate		--Only include transactions after this specific customer was launched to. This condition is on Transaction Date.
		and	pt.AddedDate <= @EndDate	--Only include transactions that were added to the database within the period that we are reporting on. This condition is on Added Date.
		and EligibleForCashBack = 1

Create clustered index ixc_Trans on #Trans(FanID)
--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('tempdb..#SinceLaunchTrans') IS NOT NULL DROP TABLE #SinceLaunchTrans
Select	FanID,
		Sum(TransactionAmount) as TotalSpend,
		Sum(CashBackEarned) as TotalCashback,
		Count(*) as TranCount
Into #SinceLaunchTrans
From #Trans
Group by FanID
--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('tempdb..#InMonthTrans') IS NOT NULL DROP TABLE #InMonthTrans
Select	FanID,
		Sum(TransactionAmount) as TotalSpend,
		Sum(CashBackEarned) as TotalCashback,
		Count(*) as TranCount
Into #InMonthTrans
From #Trans
Where AddedDate  >= @StartDate
Group by FanID



SELECT	[Type],
	DateRange,
	EarnGroup,
	Members,
	Spend,
	Reward
FROM	(
	SELECT 'Activated' as [Type],
		'Cumulative Since Launch' as DateRange,
		CASE
			WHEN TotalCashback <= 0.00 then '£00.00 or less'
			WHEN TotalCashback is null then '£00.00 or less'
			WHEN TotalCashback between 0.01 and 1.00 then '£00.01 - £1.00'
			WHEN TotalCashback between 1.01 and 2.00 then '£01.01 - £2.00'
			WHEN TotalCashback between 2.01 and 3.00 then '£02.01 - £3.00'
			WHEN TotalCashback between 3.01 and 4.00 then '£03.01 - £4.00'
			WHEN TotalCashback between 4.01 and 5.00 then '£04.01 - £5.00'
			WHEN TotalCashback between 5.01 and 6.00 then '£05.01 - £6.00'
			WHEN TotalCashback between 6.01 and 7.00 then '£06.01 - £7.00'
			WHEN TotalCashback between 7.01 and 8.00 then '£07.01 - £8.00'
			WHEN TotalCashback between 8.01 and 9.00 then '£08.01 - £9.00'
			WHEN TotalCashback between 9.01 and 10.00 then '£09.01 - £10.00'
			WHEN TotalCashback between 10.01 and 15.00 then '£10.01 and £15.00'
			WHEN TotalCashback between 15.01 and 20.00 then '£15.01 and £20.00'
			WHEN TotalCashback between 20.01 and 30.00 then '£20.01 and £30.00'
			WHEN TotalCashback between 30.01 and 40.00 then '£30.01 and £40.00'
			WHEN TotalCashback between 40.01 and 50.00 then '£40.01 and £50.00'
			WHEN TotalCashback >= £50.01  then		'£50.01 +'
		END AS EarnGroup,
		COUNT (cb.FanID) as Members,
		SUM(TotalSpend) as Spend,
		SUM(TotalCashback) as Reward
	from #cb as cb
	LEFT OUTER JOIN #SinceLaunchTrans as sl
		ON cb.FanID = sl.FanID
	GROUP BY CASE
			WHEN TotalCashback <= 0.00 THEN '£00.00 or less'
			WHEN TotalCashback IS NULL THEN '£00.00 or less'
			WHEN TotalCashback BETWEEN 0.01 and 1.00 THEN '£00.01 - £1.00'
			WHEN TotalCashback BETWEEN 1.01 and 2.00 THEN '£01.01 - £2.00'
			WHEN TotalCashback BETWEEN 2.01 and 3.00 THEN '£02.01 - £3.00'
			WHEN TotalCashback BETWEEN 3.01 and 4.00 THEN '£03.01 - £4.00'
			WHEN TotalCashback BETWEEN 4.01 and 5.00 THEN '£04.01 - £5.00'
			WHEN TotalCashback BETWEEN 5.01 and 6.00 THEN '£05.01 - £6.00'
			WHEN TotalCashback BETWEEN 6.01 and 7.00 THEN '£06.01 - £7.00'
			WHEN TotalCashback BETWEEN 7.01 and 8.00 THEN '£07.01 - £8.00'
			WHEN TotalCashback BETWEEN 8.01 and 9.00 THEN '£08.01 - £9.00'
			WHEN TotalCashback BETWEEN 9.01 and 10.00 THEN '£09.01 - £10.00'
			WHEN TotalCashback BETWEEN 10.01 and 15.00 THEN '£10.01 and £15.00'
			WHEN TotalCashback BETWEEN 15.01 and 20.00 THEN '£15.01 and £20.00'
			WHEN TotalCashback BETWEEN 20.01 and 30.00 THEN '£20.01 and £30.00'
			WHEN TotalCashback BETWEEN 30.01 and 40.00 THEN '£30.01 and £40.00'
			WHEN TotalCashback BETWEEN 40.01 and 50.00 THEN '£40.01 and £50.00'
			WHEN TotalCashback >= £50.01  THEN		'£50.01 +'
		END
UNION ALL
	SELECT 'Activated' as [Type],
		'In Month' as DateRange,
		CASE
			WHEN TotalCashback <= 0.00 THEN '£00.00 or less'
			WHEN TotalCashback IS NULL THEN '£00.00 or less'
			WHEN TotalCashback BETWEEN 0.01 AND 1.00 THEN '£00.01 - £1.00'
			WHEN TotalCashback BETWEEN 1.01 AND 2.00 THEN '£01.01 - £2.00'
			WHEN TotalCashback BETWEEN 2.01 AND 3.00 THEN '£02.01 - £3.00'
			WHEN TotalCashback BETWEEN 3.01 AND 4.00 THEN '£03.01 - £4.00'
			WHEN TotalCashback BETWEEN 4.01 AND 5.00 THEN '£04.01 - £5.00'
			WHEN TotalCashback BETWEEN 5.01 AND 6.00 THEN '£05.01 - £6.00'
			WHEN TotalCashback BETWEEN 6.01 AND 7.00 THEN '£06.01 - £7.00'
			WHEN TotalCashback BETWEEN 7.01 AND 8.00 THEN '£07.01 - £8.00'
			WHEN TotalCashback BETWEEN 8.01 AND 9.00 THEN '£08.01 - £9.00'
			WHEN TotalCashback BETWEEN 9.01 AND 10.00 THEN '£09.01 - £10.00'
			WHEN TotalCashback BETWEEN 10.01 AND 15.00 THEN '£10.01 and £15.00'
			WHEN TotalCashback BETWEEN 15.01 AND 20.00 THEN '£15.01 and £20.00'
			WHEN TotalCashback BETWEEN 20.01 AND 30.00 THEN '£20.01 and £30.00'
			WHEN TotalCashback BETWEEN 30.01 AND 40.00 THEN '£30.01 and £40.00'
			WHEN TotalCashback BETWEEN 40.01 AND 50.00 THEN '£40.01 and £50.00'
			WHEN TotalCashback >= £50.01  THEN		'£50.01 +'
		END as EarnGroup,
		COUNT (cb.FanID) as Members,
		SUM(TotalSpend) as Spend,
		SUM(TotalCashback) as Reward
	FROM #cb as cb
	LEFT OUTER JOIN #InMonthTrans as sl
		ON cb.FanID = sl.FanID
	GROUP BY CASE
			WHEN TotalCashback <= 0.00 then '£00.00 or less'
			WHEN TotalCashback IS NULL then '£00.00 or less'
			WHEN TotalCashback BETWEEN 0.01 AND 1.00 THEN '£00.01 - £1.00'
			WHEN TotalCashback BETWEEN 1.01 AND 2.00 THEN '£01.01 - £2.00'
			WHEN TotalCashback BETWEEN 2.01 AND 3.00 THEN '£02.01 - £3.00'
			WHEN TotalCashback BETWEEN 3.01 AND 4.00 THEN '£03.01 - £4.00'
			WHEN TotalCashback BETWEEN 4.01 AND 5.00 THEN '£04.01 - £5.00'
			WHEN TotalCashback BETWEEN 5.01 AND 6.00 THEN '£05.01 - £6.00'
			WHEN TotalCashback BETWEEN 6.01 AND 7.00 THEN '£06.01 - £7.00'
			WHEN TotalCashback BETWEEN 7.01 AND 8.00 THEN '£07.01 - £8.00'
			WHEN TotalCashback BETWEEN 8.01 AND 9.00 THEN '£08.01 - £9.00'
			WHEN TotalCashback BETWEEN 9.01 AND 10.00 THEN '£09.01 - £10.00'
			WHEN TotalCashback BETWEEN 10.01 AND 15.00 THEN '£10.01 and £15.00'
			WHEN TotalCashback BETWEEN 15.01 AND 20.00 THEN '£15.01 and £20.00'
			WHEN TotalCashback BETWEEN 20.01 AND 30.00 THEN '£20.01 and £30.00'
			WHEN TotalCashback BETWEEN 30.01 AND 40.00 THEN '£30.01 and £40.00'
			WHEN TotalCashback BETWEEN 40.01 AND 50.00 THEN '£40.01 and £50.00'
			WHEN TotalCashback >= £50.01  THEN		'£50.01 +'
		END
	)a
ORDER BY DateRange, EarnGroup


END