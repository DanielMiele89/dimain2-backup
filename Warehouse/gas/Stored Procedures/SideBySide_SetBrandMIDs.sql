-- =============================================
-- Author:		JEA
-- Create date: 04/03/2014
-- Description:	Updates the consumer transaction pending area with MIDI brandMIDs
-- =============================================
CREATE PROCEDURE [gas].[SideBySide_SetBrandMIDs] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	--exact match
    UPDATE Staging.ConsumerTransactionPending SET BrandMIDID = m.BrandMIDID
	FROM Staging.ConsumerTransactionPending h
	INNER JOIN Relational.BrandMID m ON h.MID = m.MID 
		and h.Narrative = m.Narrative 
		and h.LocationCountry = m.Country
	WHERE h.BrandMIDID IS NULL

	--high variance
	UPDATE Staging.ConsumerTransactionPending set BrandMIDID = m.BrandMIDID
	FROM Staging.ConsumerTransactionPending h
	INNER JOIN Relational.BrandMID m ON h.MID = m.MID 
		AND h.LocationCountry = m.Country
	WHERE m.IsHighVariance = 1
	AND H.Narrative like m.Narrative
	AND h.BrandMIDID IS NULL

END
