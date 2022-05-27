-- =============================================
-- Author:		JEA
-- Create date: 05/03/2014
-- Description:	Rebuilds indexes on working table
-- =============================================
CREATE PROCEDURE [gas].[SideBySide_WorkingIndexes_Rebuild] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    ALTER INDEX IX_Staging_ConsumerTransactionWorking_Location ON Staging.ConsumerTransactionWorking REBUILD

END
