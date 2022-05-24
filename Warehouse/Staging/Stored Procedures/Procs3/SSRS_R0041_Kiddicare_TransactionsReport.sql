-- =============================================
-- Author: Suraj Chahal
-- Create date: 05/08/2014
-- Description: Top level Kiddicare since their launch assessing their Tran count and spend
-- =============================================
CREATE PROCEDURE [Staging].[SSRS_R0041_Kiddicare_TransactionsReport]

AS
BEGIN
	SET NOCOUNT ON;

IF OBJECT_ID ('tempdb..#t1') IS NOT NULL DROP TABLE #t1
SELECT	FanID,
	CASE 
		WHEN pt.IsOnline = 1 THEN 'Online'
		ELSE 'Offline'
	END as TransactionType,
	TransactionAmount,
	MerchantID,
	CashbackEarned
INTO #t1
FROM Warehouse.Relational.PartnerTrans pt
INNER JOIN Warehouse.Relational.Outlet o
      ON pt.outletid = o.outletid
WHERE	pt.PartnerID = 4448
	AND TransactionDate >= '7 Sep 2014'


IF OBJECT_ID ('tempdb..#t2') IS NOT NULL DROP TABLE #t2
SELECT	DISTINCT
	m.HTMID,
	m.FanID
INTO #t2
FROM Warehouse.Relational.shareofwallet_Members m
INNER JOIN Warehouse.Relational.Campaign_History ch
	on m.Fanid = ch.Fanid
WHERE	m.PartnerID = 76 
	AND m.StartDate <= 'Jun 30, 2014' 
	AND (m.EndDate IS NULL OR m.EndDate >= 'Jun 30, 2014')
	AND IronOfferID = 5889 
	AND grp = 'Mail'


SELECT	g.HTM_Description as SOW_Description,
	TransactionType,
	COUNT(1) as TransactionCount,
	SUM(t.TransactionAmount) as TotalSales,
	COUNT(DISTINCT t.FanID) as UniqueSpenders,
	SUM(CashbackEarned) as TotalCashbackEarned
FROM #t1 t
INNER JOIN #t2 as t2
	ON t.FanID = t2.FanID
INNER JOIN Warehouse.Relational.HeadroomTargetingModel_Groups as g
	ON t2.HTMID = g.HTMID
GROUP BY g.HTM_Description, TransactionType
ORDER BY g.HTM_Description DESC

END