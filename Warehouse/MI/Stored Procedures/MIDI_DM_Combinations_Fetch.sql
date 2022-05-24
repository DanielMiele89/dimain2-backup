-- =============================================
-- Author:		JEA
-- Create date: 17/06/2014
-- Description:	Retrieves data to load the table storing 
-- combination information, used for MIDI data mining
-- =============================================
CREATE PROCEDURE MI.MIDI_DM_Combinations_Fetch

AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT c.ConsumerCombinationID, c.BrandID, c.MID, c.LocationCountry, c.MCCID, c.OriginatorID
		, CASE WHEN a.AcquirerID IS NOT NULL THEN a.AcquirerID
			WHEN c.LocationCountry = 'GB' THEN 7
			ELSE 9 END AS AcquirerID
	FROM Relational.ConsumerCombination c WITH (NOLOCK)
	LEFT OUTER JOIN (SELECT DISTINCT ConsumerCombinationID FROM MI.ConsumerCombination_DM_Match) D ON c.ConsumerCombinationID = d.ConsumerCombinationID
	LEFT OUTER JOIN MI.MOMCombinationAcquirer a ON c.ConsumerCombinationID = a.ConsumerCombinationID
	WHERE (C.BrandID != 943 AND c.BrandID != 944) OR d.ConsumerCombinationID IS NOT NULL

END
