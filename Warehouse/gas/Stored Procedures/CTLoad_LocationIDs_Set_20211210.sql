-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	Sets locationIDs in the staging area
-- CJM added ORDER BY
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_LocationIDs_Set_20211210]
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	--SET VALID LOCATIONS
    UPDATE Staging.CTLoad_InitialStage
	SET LocationID = L.LocationID
	FROM Staging.CTLoad_InitialStage i
	INNER JOIN Relational.Location l ON 
		i.ConsumerCombinationID = l.ConsumerCombinationID
		AND i.LocationAddress = l.LocationAddress
	WHERE l.IsNonLocational = 0

	--SET NON-LOCATION ADDRESSES
	UPDATE Staging.CTLoad_InitialStage
	SET LocationID = L.LocationID
	FROM Staging.CTLoad_InitialStage i
	INNER JOIN Relational.Location l ON 
		i.ConsumerCombinationID = l.ConsumerCombinationID
	WHERE l.IsNonLocational = 1
		AND i.LocationID IS NULL

	--DISABLE INDEX PRIOR TO INSERT
	ALTER INDEX IX_Relational_Location_Cover ON Relational.Location DISABLE

	--INSERT NEW LOCATIONS
	INSERT INTO Relational.Location (ConsumerCombinationID, LocationAddress, IsNonLocational)
	SELECT ConsumerCombinationID, LocationAddress, 0
	FROM Staging.CTLoad_InitialStage
	WHERE ConsumerCombinationID IS NOT NULL
		AND LocationID IS NULL
	ORDER BY ConsumerCombinationID -- CJM added ORDER BY

	--ENABLE INDEX FOLLOWING INSERT
	ALTER INDEX IX_Relational_Location_Cover ON Relational.Location REBUILD

	--SET NEW LOCATIONS
    UPDATE Staging.CTLoad_InitialStage
	SET LocationID = L.LocationID
	FROM Staging.CTLoad_InitialStage i
	INNER JOIN Relational.Location l ON 
		i.ConsumerCombinationID = l.ConsumerCombinationID
		AND i.LocationAddress = l.LocationAddress
	WHERE l.IsNonLocational = 0
	AND i.LocationID IS NULL

END
