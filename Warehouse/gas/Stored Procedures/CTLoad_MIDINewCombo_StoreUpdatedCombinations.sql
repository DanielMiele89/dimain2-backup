
-- =============================================
-- Author:		Rory Francis
-- Create date: 2019-04-24
-- Description:	Take all combinatiuons that have have their brand updated through the manual midi process
--				and store them for review and iterative improvements in the matching process

-- Change log:	

-- =============================================
CREATE PROCEDURE [gas].[CTLoad_MIDINewCombo_StoreUpdatedCombinations] (@RunDate DATE)

AS
BEGIN

	INSERT INTO [Staging].[CTLoad_MIDINewCombo_CombinationsUpdatedInMIDI]
	SELECT m.MatchType
		 , m.MID
		 , m.OriginatorID
		 , m.MCCID
		 , m.LocationCountry
		 , b.Narrative
		 , m.Narrative AS OriginalNarrative
		 , m.Narrative_Cleaned AS OriginalNarrative_Cleaned
		 , b.BrandID
		 , m.SuggestedBrandID
		 , 0 AS EntryReviewed
		 , @RunDate AS RunDate
	FROM Staging.CTLoad_MIDINewCombo_Branded b
	INNER JOIN Staging.CTLoad_MIDINewCombo_V2 m
		ON b.ID = m.ID
		AND (b.BrandID != m.SuggestedBrandID
		OR b.Narrative != m.Narrative)
	WHERE NOT EXISTS (SELECT 1
					  FROM [Staging].[CTLoad_MIDINewCombo_CombinationsUpdatedInMIDI]
					  WHERE RunDate = @RunDate)

END