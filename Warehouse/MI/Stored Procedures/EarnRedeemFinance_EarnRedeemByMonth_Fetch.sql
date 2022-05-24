-- =============================================
-- Author:		JEA
-- Create date: 26/06/2014
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MI].[EarnRedeemFinance_EarnRedeemByMonth_Fetch]

AS
BEGIN

	SET NOCOUNT ON;

	SELECT DATEFROMPARTS(ItemYear, ItemMonth, 1) AS MonthDate
		, BrandID
		, SUM(Earnings) AS Earnings
		, SUM(RedemptionValue) AS RedemptionValue
		, ChargeTypeID
		, PaymentMethodID
		, IsRBS
	FROM 
	(
		SELECT MONTH(TransactionDate) AS ItemMonth
			, YEAR(TransactionDate) AS ItemYear
			, BrandID
			, EarnAmount AS Earnings
			, CAST(0 AS MONEY) AS RedemptionValue
			, ChargeTypeID
			, PaymentMethodID
			, IsRBS
		FROM MI.EarnRedeemFinance_Earnings

		UNION ALL

		SELECT MONTH(ChargeDate) AS ItemMonth
			, YEAR(ChargeDate) AS ItemYear
			, BrandID
			, CAST(0 AS MONEY) AS Earnings
			, ChargeAmount AS RedemptionValue
			, ChargeTypeID
			, PaymentMethodID
			, IsRBS
		FROM MI.EarnRedeemFinance_RedemptionCharge
	) R
	GROUP BY ItemYear
		, ItemMonth
		, BrandID
		, ChargeTypeID
		, PaymentMethodID
		, IsRBS

END
