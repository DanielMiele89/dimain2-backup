-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	Used by Merchant Processing Module.
-- Enables holding table indexes prior to load
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_ConsumerTransactionHolding_EnableIndexes_DIMAIN]
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

    ALTER INDEX IX_ConsumerTransactionHolding_MainCover ON Relational.ConsumerTransactionHolding REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212
	ALTER INDEX IX_Relational_ConsumerTransactionHolding_CINIDTranDateIncl_ForMissingTranQuery ON Relational.ConsumerTransactionHolding REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212
	
END
