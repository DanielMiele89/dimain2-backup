-- =============================================
-- Author:		JEA
-- Create date: 24/04/2014
-- Description:	Retrieves distinct added dates
-- for changed transactions for the RBS MI
-- portal incremental load
-- =============================================
CREATE PROCEDURE MI.RBSPortal_AddedDatesChanged_Fetch

AS
BEGIN

	SET NOCOUNT ON;

	SELECT DISTINCT AddedDate
	FROM RBSPortal_SchemeTrans_Change
	ORDER BY AddedDate

END
