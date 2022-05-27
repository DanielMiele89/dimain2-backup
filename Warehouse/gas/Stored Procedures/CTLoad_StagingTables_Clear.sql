-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	Clears staging tables where combinations have been identified
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_StagingTables_Clear]
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

    TRUNCATE TABLE Staging.CTLoad_InitialStage
	TRUNCATE TABLE Staging.CTLoad_PaypalSecondaryID

END
