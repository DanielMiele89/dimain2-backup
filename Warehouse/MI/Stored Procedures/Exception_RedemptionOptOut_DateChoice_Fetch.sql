-- =============================================
-- Author:		JEA
-- Create date: 18/03/2014
-- Description:	List details for customers who have passed 
-- any of the exception audit test
-- =============================================
CREATE PROCEDURE [MI].[Exception_RedemptionOptOut_DateChoice_Fetch]
	
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
	
	SELECT CAST(0 AS TINYINT) AS DateChoiceID, c.SourceUID AS CIN, r.RedeemDate, r.Redemption, r.OptedOutDate
	FROM
	(
		SELECT DISTINCT r.FanID, RedeemDate, CashbackUsed AS Redemption, o.OptedOutDate
		FROM
		(
			select FanID, RedeemDate, CashbackUsed 
			from staging.Redemptions
			where cashbackused > 30
			AND RedeemDate BETWEEN @CMStartDate AND @CMEndDate
		) r
		INNER JOIN 
		(
			SELECT FanID, OptedOutDate
			FROM MI.CustomerActiveStatus
			WHERE OptedOutDate BETWEEN @CMStartDate AND @CMEndDate
		) o ON R.FanID = o.FanID
		WHERE DATEDIFF(DAY, r.RedeemDate, o.OptedOutDate) BETWEEN 0 AND 2
	) r
	INNER JOIN Relational.Customer c ON r.FanID = c.FanID
	LEFT OUTER JOIN MI.PrizeDraw_Winners p on c.FanID = p.FanID
	WHERE p.FanID IS NULL

	UNION ALL

	SELECT CAST(1 AS TINYINT) AS DateChoiceID, c.SourceUID AS CIN, r.RedeemDate, r.Redemption, r.OptedOutDate
	FROM
	(
		SELECT DISTINCT r.FanID, RedeemDate, CashbackUsed AS Redemption, o.OptedOutDate
		FROM
		(
			select FanID, RedeemDate, CashbackUsed 
			from staging.Redemptions
			where cashbackused > 30
			AND RedeemDate BETWEEN @LMStartDate AND @LMEndDate
		) r
		INNER JOIN 
		(
			SELECT FanID, OptedOutDate
			FROM MI.CustomerActiveStatus
			WHERE OptedOutDate BETWEEN @LMStartDate AND @LMEndDate
		) o ON R.FanID = o.FanID
		WHERE DATEDIFF(DAY, r.RedeemDate, o.OptedOutDate) BETWEEN 0 AND 2
	) r
	INNER JOIN Relational.Customer c ON r.FanID = c.FanID
	LEFT OUTER JOIN MI.PrizeDraw_Winners p on c.FanID = p.FanID
	WHERE p.FanID IS NULL

	UNION ALL

	SELECT CAST(3 AS TINYINT) AS DateChoiceID, c.SourceUID AS CIN, r.RedeemDate, r.Redemption, r.OptedOutDate
	FROM
	(
		SELECT DISTINCT r.FanID, RedeemDate, CashbackUsed AS Redemption, o.OptedOutDate
		FROM
		(
			select FanID, RedeemDate, CashbackUsed 
			from staging.Redemptions
			where cashbackused > 30
			AND RedeemDate BETWEEN @TMStartDate AND @TMEndDate
		) r
		INNER JOIN 
		(
			SELECT FanID, OptedOutDate
			FROM MI.CustomerActiveStatus
			WHERE OptedOutDate BETWEEN @TMStartDate AND @TMEndDate
		) o ON R.FanID = o.FanID
		WHERE DATEDIFF(DAY, r.RedeemDate, o.OptedOutDate) BETWEEN 0 AND 2
	) r
	INNER JOIN Relational.Customer c ON r.FanID = c.FanID
	LEFT OUTER JOIN MI.PrizeDraw_Winners p on c.FanID = p.FanID
	WHERE p.FanID IS NULL

END
