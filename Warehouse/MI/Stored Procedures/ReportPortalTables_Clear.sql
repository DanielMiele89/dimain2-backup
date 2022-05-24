-- =============================================
-- Author:		JEA
-- Create date: 06/05/2015
-- Description:	Clears report portal monitoring tables prior to load
-- =============================================
CREATE PROCEDURE MI.ReportPortalTables_Clear
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

    TRUNCATE TABLE MI.ReportPortalUseAnalysis
	TRUNCATE TABLE MI.ReportPortalUsage_Raw

END