-- =============================================
-- Author:		JEA
-- Create date: 20/10/2014
-- Description:	Retrieves unmatched combinations for MIDI
-- =============================================
CREATE PROCEDURE gas.CTLoad_UnmatchedCombos_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT DISTINCT MID, Narrative, LocationCountry, MCCID, OriginatorID
	FROM staging.CTLoad_MIDIHolding
	WHERE ConsumerCombinationID IS NULL

END
