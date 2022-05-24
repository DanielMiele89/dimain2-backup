
-- =============================================
-- Author:		JEA
-- Create date: 25/06/2014
-- Description:	Retrieves list of redemptions to refresh the list of charges to RBS
-- =============================================
CREATE PROCEDURE [MI].[EarnRedeemFinance_Redemptions_Fetch] 
	(
		@IsMonthEnd BIT = 1
	)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @EndDate DATETIME

	IF @IsMonthEnd = 1
	BEGIN
		SET @EndDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	END
	ELSE
	BEGIN
		SET @EndDate = GETDATE()
	END

    SELECT FanID, RedeemDate, CashbackUsed AS RedeemValue
	FROM Relational.Redemptions r
	WHERE Cancelled = 0
	AND RedeemDate < @EndDate
	ORDER BY FanID, RedeemDate

END
