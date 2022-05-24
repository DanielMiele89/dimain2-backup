-- =============================================
-- Author:		JEA
-- Create date: 17/06/2014
-- Description:	Retrieves data to load the table storing text matches
-- between ConsumerCombination and BrandMatch, used
-- for MIDI data mining
-- =============================================
CREATE PROCEDURE MI.MIDI_DM_Matches_Fetch

AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT c.ConsumerCombinationID, bm.BrandMatchID, b.BrandID, b.BrandGroupID
	FROM Relational.ConsumerCombination c WITH (NOLOCK)
	INNER JOIN Staging.BrandMatch bm ON c.Narrative LIKE bm.Narrative
	INNER JOIN Relational.Brand b ON bm.BrandID = b.BrandID

END