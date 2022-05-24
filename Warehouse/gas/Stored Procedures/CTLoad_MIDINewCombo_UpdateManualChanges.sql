
-- =============================================
-- Author:		Rory Francis
-- Create date: 2019-04-18
-- Description:	Update MIDI results from the output of manual review

-- Change log:	

-- =============================================
CREATE PROCEDURE [gas].[CTLoad_MIDINewCombo_UpdateManualChanges]

AS
BEGIN

	SET NOCOUNT ON;

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	UPDATE Staging.CTLoad_MIDINewCombo_Branded 
	SET Narrative = REPLACE(Narrative, '"', '')
	WHERE IsHighVariance = 1
	AND Narrative LIKE '"%"'


	UPDATE m
	SET m.SuggestedBrandID = b.BrandID
	FROM Staging.CTLoad_MIDINewCombo_Branded b
	INNER JOIN Staging.CTLoad_MIDINewCombo_V2 m
		ON b.ID = m.ID
		AND b.BrandID != m.SuggestedBrandID


	UPDATE m
	SET m.IsHighVariance = 1
	  , m.Narrative = b.Narrative
	FROM Staging.CTLoad_MIDINewCombo_Branded b
	INNER JOIN Staging.CTLoad_MIDINewCombo_V2 m
		ON b.ID = m.ID
		AND b.IsHighVariance = 1
	WHERE m.MID NOT IN ('020171109')


	UPDATE m
	SET SuggestedBrandID = 944
	FROM Staging.CTLoad_MIDINewCombo_V2 m
	WHERE SuggestedBrandID IS NULL


	UPDATE m
	SET IsUKSpend = CASE
						WHEN LocationCountry = 'GB' THEN 1
						WHEN B.IsNamedException = 1 THEN 1
						ELSE 0
					END
	FROM Staging.CTLoad_MIDINewCombo_V2 M
	INNER JOIN Relational.Brand B
		ON m.SuggestedBrandID = b.BrandID
	WHERE m.SuggestedBrandID != 943

END