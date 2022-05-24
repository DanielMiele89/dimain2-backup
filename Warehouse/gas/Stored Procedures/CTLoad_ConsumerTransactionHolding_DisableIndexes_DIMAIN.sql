-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	Used by Merchant Processing Module.
-- Disables holding table indexes prior to load
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_ConsumerTransactionHolding_DisableIndexes_DIMAIN]
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

    ALTER INDEX IX_ConsumerTransactionHolding_MainCover ON Relational.ConsumerTransactionHolding DISABLE
	ALTER INDEX IX_Relational_ConsumerTransactionHolding_CINIDTranDateIncl_ForMissingTranQuery ON Relational.ConsumerTransactionHolding DISABLE
	
END


