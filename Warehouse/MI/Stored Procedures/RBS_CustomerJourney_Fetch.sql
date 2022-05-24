-- =============================================
-- Author:		JEA
-- Create date: 15/12/2014
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE MI.RBS_CustomerJourney_Fetch 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT ID
		, FanID
		, CustomerJourneyStatus
		, StartDate
		, EndDate
	FROM Relational.CustomerJourneyV2

END
