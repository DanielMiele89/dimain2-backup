-- =============================================
-- Author:		JEA
-- Create date: 24/07/2013
-- Description: Retrieves available and pending unredeemed balances for the customer base
-- =============================================
CREATE PROCEDURE [MI].[EarningsAvailablePendingDaily_Fetch] 

AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @RunDate DATE
	SET @RunDate = GETDATE()

    SELECT EarningsAvailable, EarningsPending - EarningsAvailable As EarningsPending
	FROM MI.EarningsPendingAvailable_Daily
	WHERE EarningsDate = @RunDate

END
