-- =============================================
-- Author:		JEA
-- Create date: 15/04/2014
-- Description:	Retrieves CBP Dashboard offer information
-- =============================================
CREATE PROCEDURE [MI].[CBPDashboard_Month_Offers_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT WOWOfferCountMonth, WOWOfferCustomersMonth, WOWSpendMonth, WOWEarningsMonth
	FROM MI.CBPDashboard_Month_Offers

END
