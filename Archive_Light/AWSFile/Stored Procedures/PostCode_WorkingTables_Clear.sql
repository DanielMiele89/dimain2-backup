-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE AWSFile.PostCode_WorkingTables_Clear
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

   TRUNCATE TABLE AWSFile.PostCode_NewLocations_FirstStage

END
