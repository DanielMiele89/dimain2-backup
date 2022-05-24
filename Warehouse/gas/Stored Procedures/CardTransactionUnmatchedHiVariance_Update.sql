-- =============================================
-- Author:		JEA
-- Create date: 07/11/2012
-- Description:	Used by Merchant Processing Module.
-- Updates high variance combination matches in the previously unmatched holding area
-- =============================================
CREATE PROCEDURE gas.CardTransactionUnmatchedHiVariance_Update 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    UPDATE Staging.CardTransactionHoldingNoBrandMIDID
	SET BrandMIDID = m.BrandMIDID
	FROM Staging.CardTransactionHoldingNoBrandMIDID h
	INNER JOIN Staging.Combination m ON h.MID = m.MID 
	 AND h.LocationCountry = m.LocationCountry
	WHERE m.IsHighVariance = 1
	AND H.Narrative like m.Narrative
	AND h.BrandMIDID IS NULL
	
END