-- =============================================
-- Author:		JEA
-- Create date: 30/07/2013
-- Description:	Retrieves list of redemptions to refresh the list of charges to RBS
-- =============================================
CREATE PROCEDURE [MI].[ChargeOnRedeem_Redemptions_Fetch] 
	(
		@UseCurrentDate bit = 1
	)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @NegativeCount int, @EndDate DATE

	IF @UseCurrentDate = 0
	BEGIN
		SET @EndDate = DATEADD(MINUTE, -1,DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1))
	END
	ELSE
	BEGIN
		SET @EndDate = GETDATE()
	END

    SELECT FanID, RedeemDate, CashbackUsed AS RedeemValue
	FROM Relational.Redemptions r
	WHERE Cancelled = 0
	AND r.RedeemDate <= @EndDate
	ORDER BY FanID, RedeemDate

END