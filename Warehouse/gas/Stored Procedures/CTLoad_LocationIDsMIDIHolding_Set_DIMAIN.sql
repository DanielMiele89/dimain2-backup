-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	Sets locationIDs in the MIDI holding area
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_LocationIDsMIDIHolding_Set_DIMAIN]
WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	--DISABLE INDEX PRIOR TO INSERT
	--ALTER INDEX IX_Relational_Location_Cover ON Relational.Location DISABLE

	--INSERT NEW LOCATIONS
	INSERT INTO Relational.Location (ConsumerCombinationID, LocationAddress, IsNonLocational)
	SELECT DISTINCT ConsumerCombinationID, LocationAddress, 0
	FROM Staging.CTLoad_MIDIHolding
	WHERE ConsumerCombinationID IS NOT NULL
		AND LocationID IS NULL
	ORDER BY ConsumerCombinationID, LocationAddress

	--ENABLE INDEX FOLLOWING INSERT
	--ALTER INDEX IX_Relational_Location_Cover ON Relational.Location REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212 / 20201701 added fillfactor = 80


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
