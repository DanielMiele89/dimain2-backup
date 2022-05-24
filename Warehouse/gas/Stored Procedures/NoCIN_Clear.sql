-- =============================================
-- Author:		JEA
-- Create date: 08/11/2012
-- Description:	Used by Merchant Processing Module.
-- Removes all transactions with no CINID
-- from the holding area
-- =============================================
CREATE PROCEDURE [gas].[NoCIN_Clear]

AS
BEGIN

	SET NOCOUNT ON;

	DELETE
	FROM Staging.CardTransactionHolding
	WHERE CINID IS NULL
	
	DELETE FROM Staging.CardTransactionHoldingNoBrandMIDID
	WHERE CINID IS NULL
	
END