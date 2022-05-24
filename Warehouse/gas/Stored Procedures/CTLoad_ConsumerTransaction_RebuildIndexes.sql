-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	Restores the Columnstore index to 
-- the ConsumerTransaction table, allowing it to be loaded
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_ConsumerTransaction_RebuildIndexes] 
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

--	ALTER INDEX IX_ConsumerTransaction_MainCover ON Relational.ConsumerTransaction REBUILD
--	ALTER INDEX IX_Relational_ConsumerTransaction_CINIDTranDateIncl_ForMissingTranQuery ON Relational.ConsumerTransaction REBUILD

END