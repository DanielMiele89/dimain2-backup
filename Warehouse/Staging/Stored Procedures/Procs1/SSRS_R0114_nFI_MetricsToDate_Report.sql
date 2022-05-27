

-- ***************************************************************************
-- Author: Suraj Chahal
-- Create date: 06/01/2016
-- Description: nFI metrics to date report for Publisher team
-- ***************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0114_nFI_MetricsToDate_Report]
									
AS
BEGIN
	SET NOCOUNT ON;



SELECT                  distinct p.Name  as Retailer
                ,c.Name as Publisher
INTO                #offersbypublisher_nFI  
FROM                  SLC_Report.dbo.IronOfferClub ioc
inner join      SLC_Report.dbo.IronOffer io on io.ID = ioc.IronOfferID
inner join      SLC_Report.dbo.partner p on p.id = io.PartnerID
inner join    SLC_Report.dbo.club c on c.id = ioc.ClubID
cross JOIN      warehouse.InsightArchive.calendarmonths cal
where                 ClubID in (143,144,145)
                and io.StartDate <= cal.EndDate and (io.EndDate >= cal.StartDate or io.EndDate is null)
                and IsSignedOff = 1
                and cal.enddate <= getdate()
order by Publisher



/****************************************************
***********Finding Cardholders and Cards*************
****************************************************/
IF OBJECT_ID('tempdb..#Cardholdervolumes') IS NOT NULL DROP TABLE #Cardholdervolumes
SELECT	c.name as club,
		CAST(GETDATE() AS DATE) as Report_Date, 
	COUNT(p.id) as Cards,
	COUNT(DISTINCT f.ID) as Cardholders
INTO #Cardholdervolumes
FROM SLC_Report.dbo.Pan p
INNER JOIN SLC_Report.dbo.Fan f 
	ON f.CompositeID = p.CompositeID
INNER JOIN	SLC_Report.dbo.Club c 
	ON c.ID = f.clubid
WHERE	(p.removaldate is null)
	AND f.clubID in (143,144,145) 
        AND
	(
	(p.DuplicationDate IS NULL)
	OR 
	(p.DuplicationDate IS NOT NULL AND EXISTS 
						(
						SELECT	1
						FROM SLC_Report.dbo.Pan ps 
						INNER JOIN SLC_Report.dbo.Fan fs 
							ON ps.CompositeID = fs.CompositeID
						WHERE	ps.PaymentCardID = p.PaymentCardID
							AND ps.AdditionDate >= p.AdditionDate 
							AND fs.ClubID = 141 -- P4L
						)))
group by	c.Name


/****************************************************
*************Declaring Date Variables****************
****************************************************/

DECLARE	@Report_End_Date DATETIME,
	@PreviousMonthStart DATETIME,
	@PreviousMonthEnd DATETIME,
	@CurrentMonthStart DATETIME,
	@StartDate DATETIME 


SET @Report_End_Date = CAST(CONVERT(VARCHAR(10),
		CAST(CASE 
			WHEN DATEPART(DW,GETDATE())>=5 THEN DATEADD(DAY,-(DATEPART(DW,GETDATE())-5),GETDATE())
			ELSE DATEADD(DAY, -((DATEPART(DW,GETDATE())+7)-5),GETDATE())
		END AS DATE)
		,110)+' 23:59:59' AS DATETIME)
SET @PreviousMonthStart = DATEADD(MONTH,DATEDIFF(MONTH,-1,GETDATE())-2,0)
SET @PreviousMonthEnd = DATEADD(SS,-1,DATEADD(MONTH,DATEDIFF(MONTH,0,GETDATE()),0))
SET @CurrentMonthStart = DATEADD(MONTH,DATEDIFF(MONTH,-1,GETDATE())-1,0)
--SET @StartDate = CAST('2009-10-01' AS DATETIME)


/**************************************************************************
***********Find Last Month - Current Month and Cumulative Totals***********
**************************************************************************/
IF OBJECT_ID('tempdb..#transactionalbehaviour') IS NOT NULL DROP TABLE #transactionalbehaviour
SELECT	*
INTO #transactionalbehaviour
FROM	(
--**Last Month
--	SELECT	'Last Month' as Reporting_Period,
--		(@PreviousMonthStart) AS StartPeriod,
--		(@PreviousMonthEnd) AS EndPeriod,
--		min (TransactionDate) as first_tran_date,
--		max (TransactionDate) as last_tran_date,
--		c.name as club,
--		p.Name as PartnerName,
--		--COUNT(DISTINCT f.ID) as Transactors,
--		--COUNT(DISTINCT(CASE WHEN Amount > 0 THEN f.ID ELSE NULL END)) as Spenders,
--		COUNT(DISTINCT(f.ID)) as Spenders,
--		--SUM(CASE WHEN Amount > 0 THEN 1 ELSE 0 END) as Spends,
--		--SUM(CASE WHEN Amount < 0 THEN 1 ELSE 0 END) as Refunds,
--		COUNT(1) as Transactions,
--		SUM(m.Amount) as TotalSpend,
--		--(SUM(m.PartnerCommissionAmount)/SUM(m.Amount)) as Commission,
--		SUM(m.PartnerCommissionAmount) as GrossCommission,
--		SUM(m.PartnerCommissionAmount) - SUM(m.VatAmount) as NetCommission,
--		SUM(tt.Multiplier * t.CommissionEarned)as cashbackamount
--	FROM SLC_Report.dbo.Fan f
--	INNER JOIN SLC_Report.dbo.Trans t 
--		ON f.ID = t.FanID
--	INNER JOIN SLC_Report.dbo.Match m
--		ON t.MatchID = m.ID
--	INNER JOIN SLC_Report.dbo.RetailOutlet ro
--		ON m.RetailOutletID = ro.ID
--	INNER JOIN SLC_Report.dbo.Partner p
--		ON ro.PartnerID = p.ID
--	INNER JOIN SLC_Report.dbo.TransactionType tt
--		ON tt.ID = t.TypeID
--	INNER JOIN	SLC_Report.dbo.Club c 
--		ON c.ID = f.clubid
--	WHERE f.clubID in (143,144,145) --
--		AND m.Status IN (1)-- Valid transaction status
--		AND m.RewardStatus IN (0,1) -- Valid transaction status
--		AND m.TransactionDate BETWEEN @PreviousMonthStart AND @PreviousMonthEnd
--	GROUP BY p.Name, c.Name
--UNION
----**Last Month Total
--	SELECT	'Last Month' as Reporting_Period,
--		(@PreviousMonthStart) as StartPeriod,
--		(@PreviousMonthEnd) as EndPeriod,
--		min (TransactionDate) as first_tran_date,
--		max (TransactionDate) as last_tran_date,
--				c.name as club,
--		'01. Total' as PartnerName,
--		--COUNT(DISTINCT f.ID) as Transactors,
--		--COUNT(DISTINCT(CASE WHEN Amount > 0 THEN f.ID ELSE NULL END)) as Spenders,
--		COUNT(DISTINCT(f.ID)) as Spenders,
--		--SUM(CASE WHEN Amount > 0 THEN 1 ELSE 0 END) as Spends,
--		--SUM(CASE WHEN Amount < 0 THEN 1 ELSE 0 END) as Refunds,
--		COUNT(1) as Transactions,
--		SUM(m.Amount) as TotalSpend,
--		--(SUM(m.PartnerCommissionAmount)/SUM(m.Amount)) as Commission,
--		SUM(m.PartnerCommissionAmount) as GrossCommission,
--		SUM(m.PartnerCommissionAmount) - SUM(m.VatAmount) as NetCommission,
--		SUM(tt.Multiplier * t.CommissionEarned)as cashbackamount
--	FROM SLC_Report.dbo.Fan f
--	INNER JOIN SLC_Report.dbo.Trans t
--		ON f.ID = t.FanID
--	INNER JOIN SLC_Report.dbo.Match m
--		ON t.MatchID = m.ID
--	INNER JOIN SLC_Report.dbo.TransactionType tt
--		ON tt.ID = t.TypeID
--	INNER JOIN	SLC_Report.dbo.Club c 
--		ON c.ID = f.clubid
--	WHERE	f.clubID in (143,144,145) -- --12 is Quidco Club ID
--		AND m.Status IN (1)-- Valid transaction status
--		AND m.RewardStatus IN (0,1) -- Valid transaction status
--		AND m.TransactionDate BETWEEN @PreviousMonthStart AND @PreviousMonthEnd
--GROUP BY c.Name
--UNION
----**Current Month
--	SELECT	'Current Month' as Reporting_Period,
--		(@CurrentMonthStart) AS StartPeriod,
--		(@Report_End_Date) AS EndPeriod,
--		min (TransactionDate) as first_tran_date,
--		max (TransactionDate) as last_tran_date,
--				c.name as club,
--		p.Name as PartnerName,
--		--COUNT(DISTINCT f.ID) as Transactors,
--		--COUNT(DISTINCT(CASE WHEN Amount > 0 THEN f.ID ELSE NULL END)) as Spenders,
--		COUNT(DISTINCT(f.ID)) as Spenders,
--		--SUM(CASE WHEN Amount > 0 THEN 1 ELSE 0 END) as Spends,
--		--SUM(CASE WHEN Amount < 0 THEN 1 ELSE 0 END) as Refunds,
--		COUNT(1) as Transactions,
--		SUM(m.Amount) as TotalSpend,
--		--(SUM(m.PartnerCommissionAmount)/SUM(m.Amount)) as Commission,
--		SUM(m.PartnerCommissionAmount) as GrossCommission,
--		SUM(m.PartnerCommissionAmount) - SUM(m.VatAmount) as NetCommission,
--		SUM(tt.Multiplier * t.CommissionEarned)as cashbackamount
--	FROM SLC_Report.dbo.Fan f
--	INNER JOIN SLC_Report.dbo.Trans t 
--		ON f.ID = t.FanID
--	INNER JOIN SLC_Report.dbo.Match m
--		ON t.MatchID = m.ID
--	INNER JOIN SLC_Report.dbo.RetailOutlet ro
--		ON m.RetailOutletID = ro.ID
--	INNER JOIN SLC_Report.dbo.Partner p
--		ON ro.PartnerID = p.ID
--	INNER JOIN SLC_Report.dbo.TransactionType tt
--		ON tt.ID = t.TypeID
--	INNER JOIN	SLC_Report.dbo.Club c 
--		ON c.ID = f.clubid
--	WHERE	f.clubID in (143,144,145) --
--		AND m.Status IN (1)-- Valid transaction status
--		AND m.RewardStatus IN (0,1) -- Valid transaction status
--		AND m.TransactionDate BETWEEN @CurrentMonthStart AND @Report_End_Date
--	GROUP BY p.Name, c.Name
--UNION
----**Current Month Total
--	SELECT	'Current Month' as Reporting_Period,
--		(@CurrentMonthStart) AS StartPeriod,
--		(@Report_End_Date) AS EndPeriod,
--		min (TransactionDate) as first_tran_date,
--		max (TransactionDate) as last_tran_date,
--				c.name as club,
--		'01. Total' as PartnerName,
--		--COUNT(DISTINCT f.ID) as Transactors,
--		--COUNT(DISTINCT(CASE WHEN Amount > 0 THEN f.ID ELSE NULL END)) as Spenders,
--		COUNT(DISTINCT(f.ID)) as Spenders,
--		--SUM(CASE WHEN Amount > 0 THEN 1 ELSE 0 END) as Spends,
--		--SUM(CASE WHEN Amount < 0 THEN 1 ELSE 0 END) as Refunds,
--		COUNT(1) as Transactions,
--		SUM(m.Amount) as TotalSpend,
--		--(SUM(m.PartnerCommissionAmount)/SUM(m.Amount)) as Commission,
--		SUM(m.PartnerCommissionAmount) as GrossCommission,
--		SUM(m.PartnerCommissionAmount) - SUM(m.VatAmount) as NetCommission,
--		SUM(tt.Multiplier * t.CommissionEarned)as cashbackamount
--	FROM SLC_Report.dbo.Fan f
--	INNER JOIN SLC_Report.dbo.Trans t
--		ON f.ID = t.FanID
--	INNER JOIN SLC_Report.dbo.Match m
--		ON t.MatchID = m.ID
--	INNER JOIN SLC_Report.dbo.TransactionType tt
--		ON tt.ID = t.TypeID
--	INNER JOIN	SLC_Report.dbo.Club c 
--		ON c.ID = f.clubid
--	WHERE	f.clubID in (143,144,145) --
--		AND m.Status IN (1)-- Valid transaction status
--		AND m.RewardStatus IN (0,1) -- Valid transaction status
--		AND m.TransactionDate BETWEEN @CurrentMonthStart AND @Report_End_Date
--		GROUP BY c.Name
--UNION
--**To Date
	SELECT	'To Date' as Reporting_Period,
		(@StartDate) AS StartPeriod,
		(@Report_End_Date) AS EndPeriod,
		min (TransactionDate) as first_tran_date,
		max (TransactionDate) as last_tran_date,
				c.name as club,
		p.Name as PartnerName,
		--COUNT(DISTINCT f.ID) as Transactors,
		--COUNT(DISTINCT(CASE WHEN Amount > 0 THEN f.ID ELSE NULL END)) as Spenders,
		COUNT(DISTINCT(f.ID)) as Spenders,
		--SUM(CASE WHEN Amount > 0 THEN 1 ELSE 0 END) as Spends,
		--SUM(CASE WHEN Amount < 0 THEN 1 ELSE 0 END) as Refunds,
		COUNT(1) as Transactions,
		SUM(m.Amount) as TotalSpend,
		--(SUM(m.PartnerCommissionAmount)/SUM(m.Amount)) as Commission,
		SUM(m.PartnerCommissionAmount) as GrossCommission,
		SUM(m.PartnerCommissionAmount) - SUM(m.VatAmount) as NetCommission,
		SUM(tt.Multiplier * t.CommissionEarned)as cashbackamount
	FROM SLC_Report.dbo.Fan f
	INNER JOIN SLC_Report.dbo.Trans t 
		ON f.ID = t.FanID
	INNER JOIN SLC_Report.dbo.Match m
		ON t.MatchID = m.ID
	INNER JOIN SLC_Report.dbo.RetailOutlet ro
		ON m.RetailOutletID = ro.ID
	INNER JOIN SLC_Report.dbo.Partner p
		ON ro.PartnerID = p.ID
	INNER JOIN SLC_Report.dbo.TransactionType tt
		ON tt.ID = t.TypeID
	INNER JOIN	SLC_Report.dbo.Club c 
		ON c.ID = f.clubid
	WHERE	f.clubID in (143,144,145) --
		AND m.Status IN (1)-- Valid transaction status
		AND m.RewardStatus IN (0,1) -- Valid transaction status
		AND m.TransactionDate  <= @Report_End_Date
	GROUP BY p.Name, c.Name
--**To Date Total
--UNION
--	SELECT	'To Date' as Reporting_Period,
--		(@StartDate) AS StartPeriod,
--		(@Report_End_Date) AS EndPeriod,
--		min (TransactionDate) as first_tran_date,
--		max (TransactionDate) as last_tran_date,
--				c.name as club,
--		'01. Total' as PartnerName,
--		--COUNT(DISTINCT f.ID) as Transactors,
--		--COUNT(DISTINCT(CASE WHEN Amount > 0 THEN f.ID ELSE NULL END)) as Spenders,
--		COUNT(DISTINCT(f.ID)) as Spenders,
--		--SUM(CASE WHEN Amount > 0 THEN 1 ELSE 0 END) as Spends,
--		--SUM(CASE WHEN Amount < 0 THEN 1 ELSE 0 END) as Refunds,
--		COUNT(1) as Transactions,
--		SUM(m.Amount) as TotalSpend,
--		--(SUM(m.PartnerCommissionAmount)/SUM(m.Amount)) as Commission,
--		SUM(m.PartnerCommissionAmount) as GrossCommission,
--		SUM(m.PartnerCommissionAmount) - SUM(m.VatAmount) as NetCommission,
--		SUM(tt.Multiplier * t.CommissionEarned)as cashbackamount
--	FROM SLC_Report.dbo.Fan f
--	INNER JOIN SLC_Report.dbo.Trans t
--		ON f.ID = t.FanID
--	INNER JOIN SLC_Report.dbo.Match m
--		ON t.MatchID = m.ID
--	INNER JOIN SLC_Report.dbo.TransactionType tt
--		ON tt.ID = t.TypeID
--	INNER JOIN	SLC_Report.dbo.Club c 
--		ON c.ID = f.clubid
--	WHERE	f.clubID in (143,144,145) --
--		AND m.Status IN (1)-- Valid transaction status
--		AND m.RewardStatus IN (0,1) -- Valid transaction status
--		AND m.TransactionDate  <= @Report_End_Date
--		GROUP BY c.Name
	)a


SELECT	Retailer as PartnerName,
	Publisher as Club,
	first_tran_date,
	last_tran_date,
	ISNULL(Spenders,0) as Spenders,
	ISNULL(Transactions,0) as Transactions,
	ISNULL(TotalSpend,0) as TotalSpend,
	ISNULL(GrossCommission,0) as GrossCommission,
	ISNULL(NetCommission,0) as NetCommission,
	ISNULL(CashbackAmount,0) as CashbackAmount,
	ISNULL(c.Cardholders,0) as Cardholders,
	ISNULL(c.Cards,0) as Cards
FROM #offersbypublisher_nFI nfis
LEFT OUTER JOIN #transactionalbehaviour t
	ON nfis.Publisher = t.Club
	AND nfis.Retailer = t.PartnerName
	AND t.reporting_period = 'To Date'
	AND t.PartnerName not in ('01. Total')
LEFT OUTER JOIN #Cardholdervolumes c 
	on t.club = c.club


END