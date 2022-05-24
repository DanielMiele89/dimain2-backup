-- =============================================
-- Author:		JEA
-- Create date: 16/10/2014
-- Description:	Sources earnings for EarnRedeemFinance report
-- =============================================
CREATE PROCEDURE [MI].[EarnRedeemFinance_EarningsAdditional_Fetch] 
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

	SELECT a.FanID
		, CAST(0 AS SMALLINT) AS BrandID
		, a.TranDate AS TransactionDate
		, a.CashbackEarned AS EarnAmount
		, DATEADD(DAY, a.ActivationDays, a.TranDate) AS EligibleDate
		, a.AdditionalCashbackAwardTypeID AS ChargeTypeID
		, a.PaymentMethodID
		, CAST(CASE WHEN c.ClubID = 138 THEN 1 ELSE 0 END AS BIT) AS IsRBS
		, CAST(NULL AS VARCHAR(50)) AS AwardType
		, a.CashbackEarned AS EarnRedeemable
	FROM Relational.AdditionalCashbackAward A
	INNER JOIN Relational.Customer C ON A.FanID = c.FanID
	WHERE a.TranDate < @EndDate
	
	ORDER BY TransactionDate

END