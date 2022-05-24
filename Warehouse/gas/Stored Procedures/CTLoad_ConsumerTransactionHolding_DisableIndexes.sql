-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	Used by Merchant Processing Module.
-- Disables holding table indexes prior to load
-- Amendments
-- 23/09/2021 CJM Migration
-- =============================================
create PROCEDURE [gas].[CTLoad_ConsumerTransactionHolding_DisableIndexes]
	WITH EXECUTE AS OWNER
AS
IF 0 = 1 BEGIN

	SET NOCOUNT ON;

    ALTER INDEX IX_ConsumerTransactionHolding_MainCover ON Relational.ConsumerTransactionHolding DISABLE
	ALTER INDEX IX_Relational_ConsumerTransactionHolding_CINIDTranDateIncl_ForMissingTranQuery ON Relational.ConsumerTransactionHolding DISABLE
	
END

RETURN 0