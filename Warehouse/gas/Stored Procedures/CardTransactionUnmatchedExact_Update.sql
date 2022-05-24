-- =============================================
-- Author:		JEA
-- Create date: 07/11/2012
-- Description:	Used by Merchant Processing Module.
-- Updates exact combination matches in the previously unmatched holding area
-- =============================================
CREATE PROCEDURE gas.CardTransactionUnmatchedExact_Update 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    UPDATE Staging.CardTransactionHoldingNoBrandMIDID
	SET BrandMIDID = m.BrandMIDID
	FROM Staging.CardTransactionHoldingNoBrandMIDID h
	INNER JOIN Staging.Combination m ON h.MID = m.MID 
	 and h.Narrative = m.Narrative 
	 and h.LocationCountry = m.LocationCountry
	WHERE h.BrandMIDID IS NULL
	
END