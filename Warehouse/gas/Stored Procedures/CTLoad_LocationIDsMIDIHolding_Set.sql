-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	Sets locationIDs in the MIDI holding area
-- =============================================
create PROCEDURE [gas].[CTLoad_LocationIDsMIDIHolding_Set]
WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	--INSERT NEW LOCATIONS
	INSERT INTO Relational.Location (ConsumerCombinationID, LocationAddress, IsNonLocational)
	SELECT DISTINCT ConsumerCombinationID, LocationAddress, 0
	FROM Staging.CTLoad_MIDIHolding
	WHERE ConsumerCombinationID IS NOT NULL
		AND LocationID IS NULL


	--SET NEW LOCATIONS
    UPDATE i
		SET LocationID = L.LocationID
	FROM Staging.CTLoad_MIDIHolding i
	CROSS APPLY ( -- non-deterministic update
		SELECT TOP(1) L.LocationID 
		FROM Relational.Location l 
		WHERE l.IsNonLocational = 0
			AND i.ConsumerCombinationID = l.ConsumerCombinationID
			AND i.LocationAddress = l.LocationAddress	
		ORDER BY L.LocationID DESC
	) l
	WHERE i.LocationID IS NULL


END

RETURN 0



