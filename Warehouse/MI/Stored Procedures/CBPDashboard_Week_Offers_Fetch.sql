-- =============================================
-- Author:		JEA
-- Create date: 09/04/2014
-- Description:	Retrieves CBP Dashboard offer information
-- =============================================
CREATE PROCEDURE [MI].[CBPDashboard_Week_Offers_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT OfferCountWeek
		, WOWOfferCountMonth
		, WOWOfferCustomersSpendWeek
		, WOWOfferCustomersSentWeek
		, WOWOfferCustomersSpendPrevious
		, WOWOfferCustomersSentPrevious
		, WOWSpendWeek
		, WOWEarningsWeek
		, WOWSpendPrevious
		, WOWEarningsPrevious
	FROM MI.CBPDashboard_Week_Offers

END