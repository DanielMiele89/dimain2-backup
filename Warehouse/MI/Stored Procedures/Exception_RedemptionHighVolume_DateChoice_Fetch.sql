-- =============================================
-- Author:		JEA
-- Create date: 18/03/2014
-- Description:	List details for customers who have passed 
-- any of the exception audit test
-- =============================================
CREATE PROCEDURE [MI].[Exception_RedemptionHighVolume_DateChoice_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;
	
	DECLARE @CMStartDate DATE, @CMEndDate DATE, @LMStartDate DATE, @LMEndDate DATE, @TMStartDate DATE, @TMEndDate DATE

	SET @CMStartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	SET @CMEndDate = GETDATE()

	SET @LMStartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	SET @LMEndDate = DATEADD(DAY, -1, @LMStartDate)
	SET @LMStartDate = DATEADD(MONTH, -1, @LMStartDate)

	SET @TMStartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	SET @TMEndDate = DATEADD(DAY, -1, @TMStartDate)
	SET @TMStartDate = DATEADD(MONTH, -3, @TMStartDate)

	SELECT CAST(0 AS TINYINT) AS DateChoiceID, c.SourceUID AS CIN, MONTH(RedeemDate) AS RedeemMonth, YEAR(RedeemDate) AS RedeemYear, COUNT(1) AS Frequency, SUM(CashbackUsed) AS RedemptionValue
		, SUM(CASE WHEN Redeemtype = 'Trade Up' THEN 1 ELSE 0 END) AS TradeUpCount, SUM(CASE WHEN Redeemtype = 'Cash' THEN 1 ELSE 0 END) AS CashCount
	FROM Relational.Redemptions r
	INNER JOIN Relational.Customer c on r.FanID = c.FanID
	LEFT OUTER JOIN MI.PrizeDraw_Winners p on c.FanID = p.FanID
	WHERE RedeemDate BETWEEN @CMStartDate AND @CMEndDate
	AND p.FanID IS NULL
	AND r.Cancelled = 0
	GROUP BY c.SourceUID, MONTH(RedeemDate), YEAR(RedeemDate)
	HAVING COUNT(1) > 5 AND SUM(CashbackUsed) > 50

	UNION ALL

	SELECT CAST(1 AS TINYINT) AS DateChoiceID, c.SourceUID AS CIN, MONTH(RedeemDate) AS RedeemMonth, YEAR(RedeemDate) AS RedeemYear, COUNT(1) AS Frequency, SUM(CashbackUsed) AS RedemptionValue
		, SUM(CASE WHEN Redeemtype = 'Trade Up' THEN 1 ELSE 0 END) AS TradeUpCount, SUM(CASE WHEN Redeemtype = 'Cash' THEN 1 ELSE 0 END) AS CashCount
	FROM Relational.Redemptions r
	INNER JOIN Relational.Customer c on r.FanID = c.FanID
	LEFT OUTER JOIN MI.PrizeDraw_Winners p on c.FanID = p.FanID
	WHERE RedeemDate BETWEEN @LMStartDate AND @LMEndDate
	AND p.FanID IS NULL
	AND r.Cancelled = 0
	GROUP BY c.SourceUID, MONTH(RedeemDate), YEAR(RedeemDate)
	HAVING COUNT(1) > 5 AND SUM(CashbackUsed) > 50

	UNION ALL

	SELECT CAST(3 AS TINYINT) AS DateChoiceID, c.SourceUID AS CIN, MONTH(RedeemDate) AS RedeemMonth, YEAR(RedeemDate) AS RedeemYear, COUNT(1) AS Frequency, SUM(CashbackUsed) AS RedemptionValue
		, SUM(CASE WHEN Redeemtype = 'Trade Up' THEN 1 ELSE 0 END) AS TradeUpCount, SUM(CASE WHEN Redeemtype = 'Cash' THEN 1 ELSE 0 END) AS CashCount
	FROM Relational.Redemptions r
	INNER JOIN Relational.Customer c on r.FanID = c.FanID
	LEFT OUTER JOIN MI.PrizeDraw_Winners p on c.FanID = p.FanID
	WHERE RedeemDate BETWEEN @TMStartDate AND @TMEndDate
	AND p.FanID IS NULL
	AND r.Cancelled = 0
	GROUP BY c.SourceUID, MONTH(RedeemDate), YEAR(RedeemDate)
	HAVING COUNT(1) > 5 AND SUM(CashbackUsed) > 50

END