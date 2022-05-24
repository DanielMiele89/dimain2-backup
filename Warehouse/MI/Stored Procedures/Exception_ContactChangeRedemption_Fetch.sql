-- =============================================
-- Author:		JEA
-- Create date: 18/03/2014
-- Description:	List details for customers who have passed 
-- any of the exception audit test
-- =============================================
CREATE PROCEDURE [MI].[Exception_ContactChangeRedemption_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;
	
	SELECT DISTINCT c.SourceUID AS CIN, e.ChangeDate AS DetailsChanged, r.RedeemDate, r.CashbackUsed AS Redemption
	FROM MI.CustomerEmailMobileChange e
	INNER JOIN
	(
		SELECT FanID, RedeemDate, CashbackUsed
		FROM staging.Redemptions
		WHERE cashbackused > 30
		AND RedeemDate > '2013-08-08'
	) r ON e.FanID = r.FanID
	INNER JOIN Relational.Customer C on e.FanID = c.FanID
	LEFT OUTER JOIN MI.PrizeDraw_Winners p on c.FanID = p.FanID
	WHERE DATEDIFF(DAY, e.ChangeDate, r.RedeemDate) BETWEEN 0 AND 2
	AND p.FanID IS NULL

END
