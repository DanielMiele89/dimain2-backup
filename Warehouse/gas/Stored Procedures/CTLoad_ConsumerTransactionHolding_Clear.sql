-- =============================================
-- Author:		JEA
-- Create date: 07/04/2014
-- Description:	Truncates the ConsumerTransactionHolding table
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_ConsumerTransactionHolding_Clear]
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

	EXEC gas.CTLoad_ConsumerTransactionHolding_DisableIndexes

    TRUNCATE TABLE Relational.ConsumerTransactionHolding

END