-- =============================================
-- Author:		JEA
-- Create date: 05/03/2014
-- Description:	Clears the working table
-- =============================================
CREATE PROCEDURE [gas].[SideBySide_WorkingTable_Clear]
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

	TRUNCATE TABLE Staging.ConsumerTransactionWorking

END