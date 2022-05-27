-- =============================================
-- Author:		JEA
-- Create date: 30/06/2014
-- Description:	Retrieves EarnRedeemFinance information
-- =============================================
CREATE PROCEDURE [MI].[EarnRedeemFinance_EarnRedeemByMonth_Archive_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT MonthDate
		, BrandID
		, Earnings
		, RedemptionValue
		, ChargeTypeID
		, PaymentMethodID
		, IsRBS
	FROM MI.EarnRedeemFinance_EarnRedeemByMonth

END
