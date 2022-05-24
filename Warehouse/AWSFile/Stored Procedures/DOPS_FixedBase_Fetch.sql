-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [AWSFile].[DOPS_FixedBase_Fetch] 
WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

    SELECT
		*
	FROM InsightArchive.SalesVisSuite_FixedBase

END
