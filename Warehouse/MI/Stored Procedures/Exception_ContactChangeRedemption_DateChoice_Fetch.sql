-- =============================================
-- Author:		JEA
-- Create date: 18/03/2014
-- Description:	List details for customers who have passed 
-- any of the exception audit test
-- =============================================
CREATE PROCEDURE [MI].[Exception_ContactChangeRedemption_DateChoice_Fetch]
	
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

	SELECT DISTINCT CAST(0 AS TINYINT) AS DateChoiceID, c.SourceUID AS CIN, e.ChangeDate AS DetailsChanged, r.RedeemDate, r.CashbackUsed AS Redemption
	FROM MI.CustomerEmailMobileChange e
	INNER JOIN
	(
		SELECT FanID, RedeemDate, CashbackUsed
		FROM staging.Redemptions
		WHERE cashbackused > 30
		AND RedeemDate BETWEEN @CMStartDate AND @CMEndDate
	) r ON e.FanID = r.FanID
	INNER JOIN Relational.Customer C on e.FanID = c.FanID
	LEFT OUTER JOIN MI.PrizeDraw_Winners p on c.FanID = p.FanID
	WHERE DATEDIFF(DAY, e.ChangeDate, r.RedeemDate) BETWEEN 0 AND 2
	AND p.FanID IS NULL

	UNION ALL

	SELECT DISTINCT CAST(1 AS TINYINT) AS DateChoiceID, c.SourceUID AS CIN, e.ChangeDate AS DetailsChanged, r.RedeemDate, r.CashbackUsed AS Redemption
	FROM MI.CustomerEmailMobileChange e
	INNER JOIN
	(
		SELECT FanID, RedeemDate, CashbackUsed
		FROM staging.Redemptions
		WHERE cashbackused > 30
		AND RedeemDate BETWEEN @LMStartDate AND @LMEndDate
	) r ON e.FanID = r.FanID
	INNER JOIN Relational.Customer C on e.FanID = c.FanID
	LEFT OUTER JOIN MI.PrizeDraw_Winners p on c.FanID = p.FanID
	WHERE DATEDIFF(DAY, e.ChangeDate, r.RedeemDate) BETWEEN 0 AND 2
	AND p.FanID IS NULL

	UNION ALL

	SELECT DISTINCT CAST(3 AS TINYINT) AS DateChoiceID, c.SourceUID AS CIN, e.ChangeDate AS DetailsChanged, r.RedeemDate, r.CashbackUsed AS Redemption
	FROM MI.CustomerEmailMobileChange e
	INNER JOIN
	(
		SELECT FanID, RedeemDate, CashbackUsed
		FROM staging.Redemptions
		WHERE cashbackused > 30
		AND RedeemDate BETWEEN @TMStartDate AND @TMEndDate
	) r ON e.FanID = r.FanID
	INNER JOIN Relational.Customer C on e.FanID = c.FanID
	LEFT OUTER JOIN MI.PrizeDraw_Winners p on c.FanID = p.FanID
	WHERE DATEDIFF(DAY, e.ChangeDate, r.RedeemDate) BETWEEN 0 AND 2
	AND p.FanID IS NULL

END