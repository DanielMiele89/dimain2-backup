-- =============================================
-- Author:		JEA
-- Create date: 22/07/2014
-- Description:	Retrieves additional cashback earnings for calculating RBS-Funded Cashback
-- =============================================
CREATE PROCEDURE MI.ChargeOnRedeem_EarningsAdditionalCashback_Fetch 
	(
		@UseCurrentDate BIT = 0
	)
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @EndDate DATE

	IF @UseCurrentDate = 0
	BEGIN
		SET @EndDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	END
	ELSE
	BEGIN
		SET @EndDate = GETDATE()
	END

	SELECT a.FanID
		, CAST(0 AS SMALLINT) AS BrandID
		, a.TranDate AS TransactionDate
		, a.CashbackEarned AS EarnAmount
		, CAST(1 AS BIT) AS ChargeOnRedeem
		, DATEADD(DAY, a.ActivationDays, a.TranDate) AS EligibleDate
		, a.AdditionalCashbackAwardTypeID AS ChargeTypeID
	FROM Relational.AdditionalCashbackAward A
	WHERE a.TranDate < @EndDate

	ORDER BY FanID, BrandID, TransactionDate, ChargeTypeID

END