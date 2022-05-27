-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	Sets locationIDs in the staging area
-- CJM added ORDER BY
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_LocationIDs_Set]
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;
	
	IF OBJECT_ID('tempdb..#Location') IS NOT NULL DROP TABLE #Location
	SELECT	l.IsNonLocational
		,	l.ConsumerCombinationID
		,	l.LocationAddress
		,	LocationID = MAX(l.LocationID)
	INTO #Location
	FROM [Relational].[Location] l
	WHERE EXISTS (	SELECT 1
					FROM [Staging].[CTLoad_InitialStage] ct
					WHERE l.ConsumerCombinationID = ct.ConsumerCombinationID)
	GROUP BY	l.IsNonLocational
			,	l.ConsumerCombinationID
			,	l.LocationAddress
	-- (2,537,418 rows affected) / 1,000,000 rows in [Staging].[CTLoad_InitialStage] / 00:00:06
	CREATE UNIQUE CLUSTERED INDEX cx_Stuff ON #Location (ConsumerCombinationID, LocationAddress, IsNonLocational)


	--SET VALID LOCATIONS
	-- An ordinary join is okay in this instance because there's only one possible join candidate in the #Location table.
    UPDATE i
		SET LocationID = l.LocationID
	FROM [Staging].[CTLoad_InitialStage] i WITH (TABLOCK)
	INNER JOIN #Location l 
		ON i.ConsumerCombinationID = l.ConsumerCombinationID
		AND i.LocationAddress = l.LocationAddress
		AND l.IsNonLocational = 0
	-- (995,172 rows affected) / 00:00:20


	--SET NON-LOCATION ADDRESSES
	UPDATE i
		SET LocationID = L.LocationID
	FROM [Staging].[CTLoad_InitialStage] i WITH (TABLOCK)
	CROSS APPLY ( -- non-deterministic UPDATE	
		SELECT TOP(1) l.LocationID 
		FROM #Location l 
		WHERE i.ConsumerCombinationID = l.ConsumerCombinationID
			AND l.IsNonLocational = 1
		ORDER BY l.LocationID DESC
	) l
	WHERE i.LocationID IS NULL
	-- (5 rows affected) / 00:00:01

	TRUNCATE TABLE #Location

	--INSERT NEW LOCATIONS [CJM without DISTINCT, this will insert a TON of dupes]
	INSERT INTO [Relational].[Location] 
		(ConsumerCombinationID, LocationAddress, IsNonLocational)
	OUTPUT	INSERTED.LocationID
		,	INSERTED.ConsumerCombinationID
		,	INSERTED.LocationAddress
		,	INSERTED.IsNonLocational
	INTO #Location  
	SELECT	DISTINCT -- resolves dupe issue 
			ConsumerCombinationID
		,	LocationAddress
		,	0
	FROM [Staging].[CTLoad_InitialStage]
	WHERE ConsumerCombinationID IS NOT NULL
		AND LocationID IS NULL
	ORDER BY	ConsumerCombinationID -- CJM added ORDER BY
			,	LocationAddress


	--SET NEW LOCATIONS
	-- An ordinary join is okay in this instance because there's only one possible join candidate in the #Location table.
	UPDATE i
		SET LocationID = l.LocationID
	FROM [Staging].[CTLoad_InitialStage] i WITH (TABLOCK)
	INNER JOIN #Location l 
		ON i.ConsumerCombinationID = l.ConsumerCombinationID
		AND i.LocationAddress = l.LocationAddress
		AND l.IsNonLocational = 0
	WHERE i.LocationID IS NULL

END
