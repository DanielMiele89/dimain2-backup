-- =============================================
-- Author:		JEA
-- Create date: 24/04/2014
-- Description:	Returns 1 when load should be incremental and 0 when not
-- =============================================
CREATE PROCEDURE [MI].[RBSPortal_IncrementalLoad_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @DayName VARCHAR(50)

	SELECT @DayName = UPPER(DATENAME(DW, GETDATE()))

	SELECT CAST(CASE WHEN @DayName = 'SATURDAY' THEN 0 ELSE 1 END AS BIT) AS IncrementalLoad

END
