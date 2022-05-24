-- =============================================
-- Author:		JEA
-- Create date: 07/11/2012
-- Description:	Used by Merchant Processing Module.
-- Retrieves the ID of the last processed file
-- =============================================
CREATE PROCEDURE gas.CTLoad_LastFileIDProcessed_Fetch
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT FileID FROM Staging.CTLoad_LastFileProcessed
	
END