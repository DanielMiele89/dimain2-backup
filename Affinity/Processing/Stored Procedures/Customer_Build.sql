
/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description:	Empties, inserts and recreates index on the Customer table
				from SLC fan to be used for transaction pulls

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[Customer_Build]
AS 
BEGIN

	DECLARE @RowCount INT -- Logging row count;

	----------------------------------------------------------------------
	-- Clear Down
	----------------------------------------------------------------------
	--TRUNCATE TABLE Processing.Customers;
	--ALTER INDEX [cx_FanID] ON [Processing].[Customers] DISABLE
	--ALTER INDEX [ix_ClubID_CompositeID] ON [Processing].[Customers] DISABLE
	--ALTER INDEX [ix_rw_CINID] ON [Processing].[Customers] DISABLE

	----------------------------------------------------------------------
	-- Insert
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#Customers') IS NOT NULL
		DROP TABLE #Customers

	SELECT TOP 0 
		*
	INTO #Customers
	FROM Processing.Customers


	INSERT INTO #Customers
	(
		FanID
		, ProxyUserID
		, CompositeID
		, CINID
		, ClubID
		, PostcodeDistrict
		, SourceUID
		, rw
		, PostalArea
		, isNew
		, Chksum
	)
	-- MyRewards FI
	SELECT
		FanID
		, ProxyUserID
		, CompositeID
		, CINID
		, ClubID
		, PostcodeDistrict
		, SourceUID
		, rw
		, PostalArea
		, 0
		, ChkSum
	FROM (
		SELECT
			*
		FROM (
			SELECT
				f.ID as FanID
				, f.CompositeID
				, c.CINID 
				, f.ClubID
				, cu.PostcodeDistrict
				, f.SourceUID
				, ROW_NUMBER() OVER (PARTITION BY f.SourceUID ORDER BY f.ClubID) rw -- when a customer has multiple cards, use the Natwest card
				, cu.PostArea PostalArea
			FROM SLC_REPL..Fan f 
			INNER JOIN Warehouse.Relational.CINList c
				ON c.CIN = f.SourceUID
			INNER JOIN Warehouse.Relational.Customer cu	
				on cu.fanid = f.ID
			WHERE f.ClubID in (132, 138)
			and AgreedTCsDate is not null 
		) x
		WHERE x.rw = 1

		UNION ALL
		-- MyRewards nFI
		SELECT f.ID as FanID
			, f.CompositeID
			, NULL as CINID
			, f.ClubID
			, NULL as PostcodeDistrict 
			, f.SourceUID
			, 1
			, NULL as PostalArea
		FROM SLC_REPL..Fan f 
		WHERE f.ClubID in (144, 145, 147)
	) x
	CROSS APPLY (
		SELECT 
			ProxyUserID = HASHBYTES('SHA2_256', CONCAT(FanID + 2384, ',', SourceUID)) -- hashed according to specification
	) y
	CROSS APPLY (
		SELECT ChkSum = 
			CHECKSUM(
				ProxyUserID
				, CompositeID
				, CINID
				, ClubID
				, PostcodeDistrict
				, SourceUID
				, rw
				, PostalArea
				, CAST(0 AS BIT)
			)
	) z

	SELECT @RowCount = @@RowCount

	CREATE CLUSTERED INDEX CIX ON #Customers (CINID)
	--CREATE UNIQUE NONCLUSTERED INDEX UNIX ON #Customers (CINID, Chksum) WHERE CINID IS NOT NULL

	-- Update Existing
	UPDATE c
	SET PostcodeDistrict = cx.PostcodeDistrict
		, PostalArea = cx.PostalArea
		, Chksum = cx.Chksum
	FROM Processing.Customers c
	JOIN #Customers cx
		ON c.FanID = cx.FanID
		AND c.Chksum <> cx.Chksum

		
	-- Insert New
	INSERT INTO Processing.Customers
	(
		FanID
		, ProxyUserID
		, CompositeID
		, CINID
		, ClubID
		, PostcodeDistrict
		, SourceUID
		, rw
		, PostalArea
		, Chksum
		, isNew
	)
	SELECT
		FanID
		, ProxyUserID
		, CompositeID
		, CINID
		, ClubID
		, PostcodeDistrict
		, SourceUID
		, rw
		, PostalArea
		, Chksum
		, 1 AS isNew
	FROM #Customers c
	WHERE NOT EXISTS (
		SELECT 1
		FROM Processing.Customers cx
		WHERE c.FanID = cx.FanID
	)
	AND NOT EXISTS (
		SELECT 1
		FROM Processing.Customers cx
		WHERE c.CINID = cx.CINID
	)


	----------------------------------------------------------------------
	-- Create Index
	----------------------------------------------------------------------
	--ALTER INDEX [cx_FanID] ON [Processing].[Customers] REBUILD PARTITION = ALL WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, DATA_COMPRESSION = PAGE)
	--ALTER INDEX [ix_ClubID_CompositeID] ON [Processing].[Customers] REBUILD PARTITION = ALL WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, DATA_COMPRESSION = PAGE)
	--ALTER INDEX [ix_rw_CINID] ON [Processing].[Customers] REBUILD PARTITION = ALL WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, DATA_COMPRESSION = PAGE)


	RETURN @RowCount


END


