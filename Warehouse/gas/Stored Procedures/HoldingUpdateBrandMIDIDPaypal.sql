-- =============================================
-- Author:		JEA
-- Create date: 08/11/2012
-- Description:	Used by Merchant Processing Module.
-- Sets BrandMIDIDs for paypal combination matches
-- in the holding area
-- =============================================
CREATE PROCEDURE gas.HoldingUpdateBrandMIDIDPaypal
	
AS
BEGIN

	SET NOCOUNT ON;

	UPDATE Staging.CardTransactionHolding
	SET BrandMIDID = 142652 --PAYPAL
	WHERE BrandMIDID IS NULL
	AND Narrative LIKE 'Paypal%'
	
END