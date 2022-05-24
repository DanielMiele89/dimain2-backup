-- =============================================
-- Author:		JEA
-- Create date: 13/01/2014
-- Description:	Earnings and redemptions across all retailers
-- Specific report for Client Services
-- =============================================
CREATE PROCEDURE [MI].[RetailerEarningsRedemptionsFromLaunch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    --CREATE TABLE #Partners(PartnerID INT PRIMARY KEY) 

	DECLARE @StartDate DATETIME, @EndDate DATETIME

	SET @StartDate = '2013-08-08'  --launch - hardcoded
	SET @EndDate = DATEADD(MINUTE, -1,CAST(DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS DATETIME))

	--JEA 14/07/2014 Edited out WR0359
	--only partners that are not POC only
	--INSERT INTO #Partners(PartnerID)
	--SELECT DISTINCT PartnerID
	--FROM Relational.PartnerTrans T
	--INNER JOIN Relational.Customer C ON T.FanID = c.FanID
	--WHERE T.TransactionDate BETWEEN @StartDate AND @EndDate
	--AND C.POC_Customer = 0

	SELECT COALESCE(e.Retailer, r.Retailer) AS Retailer
		, ISNULL(E.Earnings, 0) AS Earnings
		, ISNULL(r.Redemption, 0) AS Redemption
		, @StartDate AS StartDate
		, @EndDate AS EndDate
	FROM
	(
		SELECT p.PartnerID, p.PartnerName AS Retailer, sum(t.CashbackEarned) AS Earnings
		FROM Relational.PartnerTrans t
		INNER JOIN Relational.[Partner] p on t.PartnerID = p.PartnerID
		--INNER JOIN #Partners s ON p.PartnerID = s.PartnerID
		WHERE T.TransactionDate BETWEEN @StartDate AND @EndDate
		GROUP BY p.PartnerID, p.PartnerName
	) e

	FULL OUTER JOIN

	(
		SELECT p.PartnerID, p.PartnerName AS Retailer, sum(r.CashbackUsed) AS Redemption
		FROM Relational.Redemptions r
		INNER JOIN Relational.[Partner] p on r.PartnerID = p.PartnerID
		--INNER JOIN #Partners s ON p.PartnerID = s.PartnerID
		LEFT OUTER JOIN MI.PrizeDraw_Winners w ON r.FanID = w.FanID
		WHERE r.RedeemDate BETWEEN @StartDate AND @EndDate
		AND (w.FanID IS NULL OR r.RedeemDate < '2014-01-10')
		GROUP BY p.PartnerID, p.PartnerName
	) r ON e.PartnerID = r.PartnerID

	ORDER BY Retailer

	--DROP TABLE #Partners

END