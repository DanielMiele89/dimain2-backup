-- =============================================
--- Author:		JEA
-- Create date: 13/01/2014
-- Description:	Returns highest single redemption total since scheme launch
-- Specific report for Client Services
-- =============================================
CREATE PROCEDURE [MI].[RetailerHighestRedemptionFromLaunch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @StartDate DATETIME, @EndDate DATETIME

	SET @StartDate = '2013-08-08'  --launch - hardcoded
	SET @EndDate = DATEADD(MINUTE, -1,CAST(DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1) AS DATETIME))

	SELECT Redemption
	FROM
	(
		SELECT r.FanID, SUM(CashbackUsed) AS Redemption, ROW_NUMBER() OVER (ORDER BY SUM(CashbackUsed) DESC) AS RedeemOrdinal
		FROM Relational.Redemptions r
		LEFT OUTER JOIN MI.PrizeDraw_Winners w ON r.FanID = w.FanID
		WHERE RedeemDate BETWEEN @StartDate AND @EndDate
		AND (w.FanID IS NULL OR r.RedeemDate < '2014-01-10')
		AND Cancelled = 0
		GROUP BY r.FanID
	) r WHERE RedeemOrdinal = 1

END