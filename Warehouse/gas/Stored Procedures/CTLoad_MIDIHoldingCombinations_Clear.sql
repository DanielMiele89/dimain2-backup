-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	removes all entries from the MIDI
-- holding table for which combinations have been found
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_MIDIHoldingCombinations_Clear]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    DELETE FROM Staging.CTLoad_MIDIHolding
	WHERE ConsumerCombinationID IS NOT NULL
	AND LocationID IS NOT NULL

	DELETE FROM Staging.CreditCardLoad_MIDIHolding
	WHERE ConsumerCombinationID IS NOT NULL

END