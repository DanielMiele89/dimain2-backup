-- =============================================
-- Author:		JEA
-- Create date: 18/03/2014
-- Description:	List details for customers who have passed 
-- any of the exception audit test
-- =============================================
CREATE PROCEDURE [MI].[Exception_RedemptionOptOut_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;
	
	SELECT c.SourceUID AS CIN, r.RedeemDate, r.Redemption, r.OptedOutDate
	FROM
	(
		SELECT DISTINCT r.FanID, RedeemDate, CashbackUsed AS Redemption, o.OptedOutDate
		FROM
		(
			select FanID, RedeemDate, CashbackUsed 
			from staging.Redemptions
			where cashbackused > 30
			AND RedeemDate > '2013-08-08'
		) r
		INNER JOIN 
		(
			SELECT FanID, OptedOutDate
			FROM MI.CustomerActiveStatus
			WHERE OptedOutDate >= '2013-08-08'
		) o ON R.FanID = o.FanID
		WHERE DATEDIFF(DAY, r.RedeemDate, o.OptedOutDate) BETWEEN 0 AND 2
	) r
	INNER JOIN Relational.Customer c ON r.FanID = c.FanID
	LEFT OUTER JOIN MI.PrizeDraw_Winners p on c.FanID = p.FanID
	WHERE p.FanID IS NULL

END