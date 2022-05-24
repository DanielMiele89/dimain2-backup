-- =============================================
-- Author:		JEA
-- Create date: 08/11/2012
-- Description:	Used by Merchant Processing Module.
-- Sets BrandMIDIDs for exact combination matches
-- in the holding area
-- =============================================
CREATE PROCEDURE gas.HoldingUpdateBrandMIDIDExactMatch
	
AS
BEGIN

	SET NOCOUNT ON;

	UPDATE Staging.CardTransactionHolding SET BrandMIDID = m.BrandMIDID
	FROM Staging.CardTransactionHolding h
	INNER JOIN Staging.Combination m ON h.MID = m.MID 
		and h.Narrative = m.Narrative 
		and h.LocationCountry = m.LocationCountry
	WHERE h.BrandMIDID IS NULL
	
END
