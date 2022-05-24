-- =============================================
-- Author:		JEA
-- Create date: 24/07/2013
-- Description:	Earnings By Class By Date
-- =============================================
CREATE PROCEDURE MI.EarningsByClassDaily_Fetch 

AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @RunDate DATE
	SET @RunDate = GETDATE()

    SELECT c.ID, c.EarningsClass, e.CustomerCount, e.EarningsDate
	FROM MI.EarningsByClass_Daily e
	INNER JOIN MI.EarningsClass c ON E.EarningsClassID = c.ID
	WHERE e.EarningsDate = @RunDate

END
