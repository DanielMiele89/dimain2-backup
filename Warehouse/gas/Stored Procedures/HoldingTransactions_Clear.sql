-- =============================================
-- Author:		JEA
-- Create date: 08/11/2012
-- Description:	Used by Merchant Processing Module.
-- Clear holding transactions, ready for the next file
-- =============================================
CREATE PROCEDURE [gas].[HoldingTransactions_Clear]
	
AS
BEGIN

	SET NOCOUNT ON;

	DELETE FROM Staging.CardTransactionHolding
	
END
