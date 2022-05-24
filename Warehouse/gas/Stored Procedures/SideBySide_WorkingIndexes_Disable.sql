-- =============================================
-- Author:		JEA
-- Create date: 05/03/2014
-- Description:	Disables indexes on working table
-- =============================================
CREATE PROCEDURE [gas].[SideBySide_WorkingIndexes_Disable] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    ALTER INDEX IX_Staging_ConsumerTransactionWorking_Location ON Staging.ConsumerTransactionWorking DISABLE

END