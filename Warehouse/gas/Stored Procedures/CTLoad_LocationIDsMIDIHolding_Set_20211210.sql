-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	Sets locationIDs in the MIDI holding area
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_LocationIDsMIDIHolding_Set_20211210]
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

	--ENABLE INDEX FOLLOWING INSERT
	--ALTER INDEX IX_Relational_Location_Cover ON Relational.Location REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212 / 20201701 added fillfactor = 80



	--SET NEW LOCATIONS
    UPDATE i
		SET LocationID = L.LocationID
	FROM Staging.CTLoad_MIDIHolding i
	INNER JOIN Relational.Location l 
		ON i.ConsumerCombinationID = l.ConsumerCombinationID
		AND i.LocationAddress = l.LocationAddress
	WHERE l.IsNonLocational = 0
		AND i.LocationID IS NULL



END
