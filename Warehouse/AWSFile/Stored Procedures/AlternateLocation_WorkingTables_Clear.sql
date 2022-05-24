-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE AWSFile.AlternateLocation_WorkingTables_Clear 
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

    TRUNCATE TABLE Staging.AlternateLocation_File
	TRUNCATE TABLE Staging.AlternateLocation_ConsumerCombination
	TRUNCATE TABLE AWSFile.ConsumerCombination_AlternateLocation
	
END