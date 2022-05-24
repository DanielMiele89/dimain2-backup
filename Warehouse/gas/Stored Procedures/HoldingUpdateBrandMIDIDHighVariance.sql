-- =============================================
-- Author:		JEA
-- Create date: 08/11/2012
-- Description:	Used by Merchant Processing Module.
-- Sets BrandMIDIDs for hig variance combination matches
-- in the holding area
-- =============================================
CREATE PROCEDURE gas.HoldingUpdateBrandMIDIDHighVariance
	
AS
BEGIN

	SET NOCOUNT ON;

	UPDATE Staging.CardTransactionHolding set BrandMIDID = m.BrandMIDID
	FROM Staging.CardTransactionHolding h
	INNER JOIN Staging.Combination m ON h.MID = m.MID 
		AND h.LocationCountry = m.LocationCountry
	WHERE m.IsHighVariance = 1
	AND H.Narrative like m.Narrative
	AND h.BrandMIDID IS NULL
	
END
