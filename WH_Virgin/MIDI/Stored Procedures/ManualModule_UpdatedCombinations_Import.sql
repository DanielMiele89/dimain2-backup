﻿
-- =============================================
-- Author:		Rory Francis
-- Create date: 2019-04-24
-- Description:	Take all combinatiuons that have have their brand updated through the manual midi process
--				and store them for review and iterative improvements in the matching process

-- Change log:	

-- =============================================
CREATE PROCEDURE [MIDI].[ManualModule_UpdatedCombinations_Import] (@RunDate DATE)

AS
BEGIN

	UPDATE mnc
	SET mnc.UpdatedBrandID = COALESCE(bi.SuggestedBrandID, mnc.OriginalBrandID)
	FROM [MIDI].[CTLoad_MIDINewCombo] mnc
	LEFT JOIN [MIDI].[MIDINewCombo_Brand_Import] bi
		ON mnc.ID = bi.ID

	UPDATE mnc
	SET mnc.UpdatedNarrative = COALESCE(ni.Narrative, mnc.OriginalNarrative)
	FROM [MIDI].[CTLoad_MIDINewCombo] mnc
	LEFT JOIN [MIDI].[MIDINewCombo_Narrative_Import] ni
		ON mnc.ID = ni.ID
	
	UPDATE mnc
	SET [mnc].[IsHighVariance] = 1
	FROM [MIDI].[CTLoad_MIDINewCombo] mnc
	WHERE [mnc].[OriginalNarrative] != [mnc].[UpdatedNarrative]
	AND ([mnc].[UpdatedNarrative] LIKE '%[%]%' OR [mnc].[UpdatedNarrative] LIKE '%[_]%')

	--DECLARE @RunDate DATE = GETDATE()

	DELETE
	FROM [MIDI].[CTLoad_MIDINewCombo_Log]
	WHERE [MIDI].[CTLoad_MIDINewCombo_Log].[RunDate] = @RunDate

	INSERT INTO [MIDI].[CTLoad_MIDINewCombo_Log]
	SELECT *
		 , 0 AS EntryReviewed
		 , @RunDate AS RunDate
	FROM [MIDI].[CTLoad_MIDINewCombo] m

END