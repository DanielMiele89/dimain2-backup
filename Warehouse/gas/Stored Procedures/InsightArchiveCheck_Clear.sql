-- =============================================
-- Author:		JEA
-- Create date: 23/10/2015
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE gas.InsightArchiveCheck_Clear 
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

    TRUNCATE TABLE InsightArchive.InsightArchiveCheck

END
