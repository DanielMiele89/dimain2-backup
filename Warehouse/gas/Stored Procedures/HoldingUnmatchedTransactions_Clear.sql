-- =============================================
-- Author:		JEA
-- Create date: 08/11/2012
-- Description:	Used by Merchant Processing Module.
-- Removes unmatched transactions from the holding area
-- =============================================
CREATE PROCEDURE gas.HoldingUnmatchedTransactions_Clear
	
AS
BEGIN

	SET NOCOUNT ON;

	DELETE FROM Staging.CardTransactionHolding
	WHERE BrandMIDID IS NULL
	
END