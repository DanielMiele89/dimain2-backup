-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	Used by Merchant Processing Module.
-- Enables holding table indexes prior to load
-- Amendments
-- 23/09/2021 CJM Migration
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_ConsumerTransactionHolding_EnableIndexes]
	WITH EXECUTE AS OWNER
AS
IF 0 = 1 BEGIN

	SET NOCOUNT ON;

    ALTER INDEX IX_ConsumerTransactionHolding_MainCover ON Relational.ConsumerTransactionHolding REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212
	ALTER INDEX IX_Relational_ConsumerTransactionHolding_CINIDTranDateIncl_ForMissingTranQuery ON Relational.ConsumerTransactionHolding REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212
	
END

RETURN 0