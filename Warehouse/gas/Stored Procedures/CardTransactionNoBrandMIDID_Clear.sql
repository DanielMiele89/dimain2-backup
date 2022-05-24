-- =============================================
-- Author:		JEA
-- Create date: 07/11/2012
-- Description:	Used by Merchant Processing Module.
-- Removes previously unmatched transactions that have now been matched
-- =============================================
CREATE PROCEDURE gas.CardTransactionNoBrandMIDID_Clear
	
AS
BEGIN

	SET NOCOUNT ON;

    DELETE FROM Staging.CardTransactionHoldingNoBrandMIDID
	WHERE NOT BrandMIDID IS NULL
	
END