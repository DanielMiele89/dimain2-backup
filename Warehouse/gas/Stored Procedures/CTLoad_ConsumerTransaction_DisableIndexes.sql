-- =============================================
-- Author:		JEA
-- Create date: 11/04/2014
-- Description:	Removes the Columnstore index from 
-- the ConsumerTransaction table, allowing it to be loaded
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_ConsumerTransaction_DisableIndexes] 
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

--	ALTER INDEX IX_ConsumerTransaction_MainCover ON Relational.ConsumerTransaction DISABLE
--	ALTER INDEX IX_Relational_ConsumerTransaction_CINIDTranDateIncl_ForMissingTranQuery ON Relational.ConsumerTransaction DISABLE

END
