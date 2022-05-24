
-- =============================================
-- Author:		<Shaun Hide>
-- Create date: <01/02/2017>
-- Description:	<Cumulative Gains for RBS>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_LIVE_RBS_CumulativeGains_Calculate_DIMAIN]
	@BrandList VARCHAR(500)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @time DATETIME

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- Start', @time OUTPUT


	IF OBJECT_ID('tempdb..#Brand') IS NOT NULL DROP TABLE #Brand
	CREATE TABLE #Brand
		(
			BrandID INT
			,BrandName VARCHAR(50)
			,RowNo INT
		)

	IF @BrandList IS NULL
		BEGIN
			INSERT INTO #Brand
				SELECT	BrandID
						,BrandName
						,ROW_NUMBER() OVER (ORDER BY BrandID) RowNo
				FROM	Warehouse.ExcelQuery.ROCEFT_BrandList
		END
	ELSE
		BEGIN
			INSERT INTO #Brand
				SELECT	BrandID
						,BrandName
						,ROW_NUMBER() OVER (ORDER BY BrandID) RowNo
				FROM	Warehouse.ExcelQuery.ROCEFT_BrandList
				WHERE	CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0
		END
	
	CREATE UNIQUE CLUSTERED INDEX CIX_BrandID ON #Brand (BrandID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- #Brand', @time OUTPUT

	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT	cc.BrandID,
			cc.ConsumerCombinationID
	INTO	#CC
	FROM	Warehouse.Relational.ConsumerCombination cc WITH (NOLOCK)
	JOIN	#Brand br
		ON	cc.BrandID = br.BrandID


	CREATE CLUSTERED INDEX cix_ConsumerCombinationID ON #CC (ConsumerCombinationID)
	CREATE NONCLUSTERED INDEX nix_ConsumerCombinationID_BrandID ON #CC (ConsumerCombinationID) INCLUDE (BrandID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- #CC', @time OUTPUT

	----------------------------------------------------------------------------------------------
	-- Fixed Base - Find a random 1.5m MyRewards Customers

	IF OBJECT_ID('tempdb..#Customer') IS NOT NULL DROP TABLE #Customer
	SELECT	TOP 1500000 *
	INTO	#Customer
	FROM	(
				SELECT	CINID
				FROM	Warehouse.Relational.Customer c
				JOIN	Warehouse.Relational.CINList cl
					ON	cl.CIN = c.SourceUID
				WHERE	c.CurrentlyActive = 1
					AND NOT EXISTS
						(
							SELECT	*
							FROM	Warehouse.Staging.Customer_DuplicateSourceUID dup
							WHERE	EndDate IS NULL
								AND c.SourceUID = dup.SourceUID
						)
			) a
	-- ORDER BY NEWID()

	CREATE CLUSTERED INDEX cix_CINID ON #Customer(CINID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- #Customer', @time OUTPUT

	IF OBJECT_ID('tempdb..#Base') IS NOT NULL DROP TABLE #Base
	SELECT	a.CINID,
			c.PostalSector,
			c.Gender,
			COALESCE(c.Region,'Unknown') AS Region,
			CASE	
			  WHEN c.AgeCurrent < 18 OR c.AgeCurrent IS NULL THEN '99. Unknown'
			  WHEN c.AgeCurrent BETWEEN 18 AND 24 THEN '01. 18 to 24'
			  WHEN c.AgeCurrent BETWEEN 25 AND 34 THEN '02. 25 to 34'
			  WHEN c.AgeCurrent BETWEEN 35 AND 44 THEN '03. 35 to 44'
			  WHEN c.AgeCurrent BETWEEN 45 AND 54 THEN '04. 45 to 54'
			  WHEN c.AgeCurrent BETWEEN 55 AND 64 THEN '05. 55 to 64'
			  WHEN 65 <= c.AgeCurrent THEN '06. 65+'
			END AS AgeGroup,
			CASE	
			  WHEN c.AgeCurrent < 18 OR c.AgeCurrent IS NULL THEN 7
			  WHEN c.AgeCurrent BETWEEN 18 AND 24 THEN 1
			  WHEN c.AgeCurrent BETWEEN 25 AND 34 THEN 2
			  WHEN c.AgeCurrent BETWEEN 35 AND 44 THEN 3
			  WHEN c.AgeCurrent BETWEEN 45 AND 54 THEN 4
			  WHEN c.AgeCurrent BETWEEN 55 AND 64 THEN 5
			  WHEN 65 <= c.AgeCurrent THEN 6
			END AS Age_Group,
			ISNULL((cam.[CAMEO_CODE_GROUP] +'-'+ camg.CAMEO_CODE_GROUP_Category),'99. Unknown') AS CameoGroup,
			c.MarketableByEmail,
			ISNULL(camg.Social_Class,'U') as SocialClass,
			CASE
			  WHEN ISNULL(camg.Social_Class,'U') = 'AB' THEN 1
			  WHEN ISNULL(camg.Social_Class,'U') = 'C1' THEN 2
			  WHEN ISNULL(camg.Social_Class,'U') = 'C2' THEN 3
			  WHEN ISNULL(camg.Social_Class,'U') = 'DE' THEN 4
			  ELSE 5
			END AS Social_Class
	INTO	#Base
	FROM	#Customer a
	JOIN	Warehouse.Relational.CINList cl
		ON	a.CINID = cl.CINID
	JOIN	Warehouse.Relational.Customer c
		ON	cl.CIN = c.SourceUID
	LEFT JOIN Warehouse.Relational.CAMEO cam
		ON	c.PostCode = cam.PostCode
	LEFT JOIN Warehouse.Relational.CAMEO_CODE_GROUP camg
		ON	camg.CAMEO_CODE_GROUP = cam.CAMEO_CODE_GROUP

	CREATE CLUSTERED INDEX cix_CINID on #Base (CINID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- #Base', @time OUTPUT

	IF OBJECT_ID('tempdb..#BaseCombo') IS NOT NULL DROP TABLE #BaseCombo
	SELECT	b.*,
			hc.ComboID
	INTO	#BaseCombo
	FROM	#Base b
	JOIN	Warehouse.Relational.HeatmapCombinations hc
		ON	b.Gender = hc.Gender
		AND	b.AgeGroup = hc.HeatmapAgeGroup
		AND	b.CameoGroup = hc.HeatmapCameoGroup

	CREATE CLUSTERED INDEX cix_CINID ON #BaseCombo (CINID)
	CREATE NONCLUSTERED INDEX ix_ComboIDCINID ON #BaseCombo (ComboID, CINID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- #BaseCombo', @time OUTPUT

	IF OBJECT_ID('tempdb..#Dates') IS NOT NULL DROP TABLE #Dates
	CREATE TABLE #Dates
		(
			ID INT NOT NULL PRIMARY KEY
			,CycleStart DATE
			,CycleEnd DATE
			,Seasonality_CycleID INT
		)

	;WITH CTE
	 AS (	
			SELECT	1 AS ID
					,CAST('2017-03-30' AS DATE) AS CycleStart
					,CAST('2017-04-26' AS DATE) AS CycleEnd
					,4 AS Seasonality_CycleID
		
			UNION ALL
		
			SELECT	ID + 1
					,CAST(DATEADD(DAY,28,CycleStart) AS DATE)
					,CAST(DATEADD(DAY,28,CycleEnd) AS DATE)
					,CASE
						WHEN Seasonality_CycleID < 13 THEN Seasonality_CycleID + 1
						ELSE Seasonality_CycleID - 12
					 END
			FROM	CTE
			WHERE	ID < 68
		)
	INSERT INTO #Dates
		SELECT	* 
		FROM	CTE
	OPTION (MAXRECURSION 68)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- #Dates', @time OUTPUT

	----------------------------------------------------------------------------------
	-- Dates Subsetted - Most Recent allowing for Transactional Lag
	
	IF OBJECT_ID('tempdb..#WorkingDates') IS NOT NULL DROP TABLE #WorkingDates
	SELECT	b.*
			,ROW_NUMBER() OVER (ORDER BY b.ID ASC) AS DateRow
	INTO	#WorkingDates
	FROM	(SELECT	*
			 FROM	#Dates 
			 WHERE	CycleStart <= CAST(DATEADD(DAY,-7,GETDATE()) AS DATE)
				AND CAST(DATEADD(DAY,-7,GETDATE()) AS DATE) <= CycleEnd) a
	JOIN	#Dates b
		ON  a.ID - 2 < b.ID
		AND b.ID < a.ID

	CREATE CLUSTERED INDEX cix_DateRow ON #WorkingDates(DateRow)
	CREATE NONCLUSTERED INDEX nix_CycleStart ON #WorkingDates(CycleStart)
	CREATE NONCLUSTERED INDEX nix_CycleEnd ON #WorkingDates(CycleEnd)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- #WorkingDates', @time OUTPUT

	----------------------------------------------------------------------------------
	-- Segment Lengths

	IF OBJECT_ID('tempdb..#Settings') IS NOT NULL DROP TABLE #Settings
	SELECT	br.BrandName
			,br.BrandID
			,COALESCE(part.Acquire,blk.acquireL,lk.AcquireL,12) as AcquireL
			,COALESCE(part.Lapsed,blk.LapserL,lk.LapserL,6) as LapserL
			,br.SectorID
	INTO	#Settings
	FROM	Warehouse.Relational.Brand br
	LEFT JOIN	
		(		SELECT	DISTINCT p.BrandID,
						part.Acquire,
						part.Lapsed
				FROM	Warehouse.Relational.Partner p
				JOIN	Warehouse.Segmentation.ROC_Shopper_Segment_Partner_Settings part
					ON	p.PartnerID = part.PartnerID
				WHERE	EndDate IS NULL
		) part
		ON	br.BrandID = part.BrandID
	LEFT JOIN	Warehouse.ExcelQuery.ROCEFT_BrandSegmentLengthOverride blk 
			on	br.BrandID = blk.BrandID
	LEFT JOIN	Warehouse.ExcelQuery.ROCEFT_SectorSegmentLengthOverride lk 
			on	br.SectorID = lk.SectorID
	JOIN	#Brand b
		ON	br.BrandID = b.BrandID

	CREATE CLUSTERED INDEX cix_BrandID ON #Settings (BrandID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- #Settings', @time OUTPUT
	
	-- Adjust for ridiculous Acquire Lengths
	UPDATE s
    SET    AcquireL = 60
    FROM #Settings s
    WHERE 60 < AcquireL

	----------------------------------------------------------------------------------
	-- Date Table + Segment Lengths

	IF OBJECT_ID('tempdb..#JoinDates') IS NOT NULL DROP TABLE #JoinDates
	SELECT	ID,
			BrandID,
			CAST(DATEADD(MONTH,-b.AcquireL,DATEADD(DAY,-1,CycleStart)) AS DATE) AS AcquireDate,
			CAST(DATEADD(MONTH,-b.LapserL,DATEADD(DAY,-1,CycleStart)) AS DATE) AS LapsedDate,
			CAST(DATEADD(DAY,-1,CycleStart) AS DATE) AS MaxDate,
			CycleStart,
			CycleEnd,
			Seasonality_CycleID,
			DateRow
	INTO	#JoinDates
	FROM	#WorkingDates a
	CROSS JOIN #Settings b

	CREATE CLUSTERED INDEX cix_ID ON #JoinDates(ID,BrandID)
	CREATE NONCLUSTERED INDEX nix_AcquireD ON #JoinDates(AcquireDate)
	CREATE NONCLUSTERED INDEX nix_LapsedD ON #JoinDates(LapsedDate)
	CREATE NONCLUSTERED INDEX nix_MaxD ON #JoinDates(MaxDate)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- #JoinDates', @time OUTPUT

	-------------------------------------------------
	-- Pull Transaction Data To Segment Customers
	DECLARE @MinDate DATE,
			@MaxDate DATE
	SELECT	@MinDate = MIN(AcquireDate),
			@MaxDate = MAX(MaxDate)
	FROM	#JoinDates
	WHERE	DateRow = 1

	IF OBJECT_ID('tempdb..#InitialSegmentation') IS NOT NULL DROP TABLE #InitialSegmentation
	SELECT	lt.BrandID,
			lt.CINID,
			lt.LastTransactionDate,
			x.CurrentSegmentation,
			0 AS NewSegmentation
	INTO #InitialSegmentation
	FROM (SELECT * FROM #JoinDates WHERE DateRow = 1) d -- 450 rows
	CROSS APPLY (
		SELECT	cc.BrandID,
				ct.CINID,
				MAX(TranDate) AS LastTransactionDate
		FROM Warehouse.Relational.ConsumerTransaction_MyRewards ct WITH (NOLOCK)
		INNER JOIN #CC cc 
			ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
		JOIN #Customer c
			ON ct.CINID = c.CINID
		WHERE cc.BrandID = d.BrandID  
			AND 0 < ct.Amount
			AND	@MinDate <= ct.TranDate AND ct.TranDate <= @MaxDate
		GROUP BY cc.BrandID,
				 ct.CINID
	) lt
	CROSS APPLY (
		SELECT CurrentSegmentation = CASE
			  WHEN lt.LastTransactionDate < d.AcquireDate THEN 7
	          WHEN d.AcquireDate <= lt.LastTransactionDate AND lt.LastTransactionDate <= d.LapsedDate THEN 8
			  ELSE 9
			END
	) x
	WHERE x.CurrentSegmentation <> 7

	CREATE CLUSTERED INDEX cix_BrandID_CINID ON #InitialSegmentation (BrandID,CINID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- #InitialSegmentation', @time OUTPUT

	-------------------------------------------------

	IF OBJECT_ID('tempdb..#CustomerDates') IS NOT NULL DROP TABLE #CustomerDates
	SELECT	a.BrandID,
			a.CINID,
			j.AcquireDate,
			j.MaxDate
	INTO	#CustomerDates
	FROM	#InitialSegmentation a
	JOIN	#JoinDates j
		ON	a.BrandID = j.BrandID
		AND	j.DateRow = 1

	CREATE CLUSTERED INDEX cix_CINIDBrandID ON #CustomerDates (CINID, BrandID)
	CREATE NONCLUSTERED INDEX ix_BrandID_CINID ON #CustomerDates (BrandID, CINID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- #CustomerDates', @time OUTPUT

	DECLARE @HistoricMinDate DATE,
			@HistoricMaxDate DATE,
			@FutureMinDate DATE,
			@FutureMaxDate DATE
	SELECT	@HistoricMinDate = MIN(AcquireDate),
			@HistoricMaxDate = MAX(MaxDate),
			@FutureMinDate = MIN(CycleStart),
			@FutureMaxDate = MAX(CycleEnd)
	FROM	#JoinDates
	WHERE	DateRow = 1

	-- Find Historic Transactions for Lapsed & Shopper
	IF OBJECT_ID('tempdb..#Historic') IS NOT NULL DROP TABLE #Historic
	SELECT	c.BrandID,
			c.CINID,
			SUM(CASE WHEN AcquireDate <= TranDate AND TranDate <= MaxDate THEN ct.Amount ELSE 0 END) AS Sales,
			COUNT(CASE WHEN AcquireDate <= TranDate AND TranDate <= MaxDate THEN ct.Amount ELSE NULL END) AS Frequency
	INTO	#Historic
	FROM	Warehouse.Relational.ConsumerTransaction_MyRewards ct WITH (NOLOCK)
	JOIN	#CC cc
		ON	ct.ConsumerCombinationID = cc.ConsumerCombinationID
	JOIN	#CustomerDates c
		ON	ct.CINID = c.CINID
		AND	cc.BrandID = c.BrandID
	WHERE	0 < ct.Amount
		AND	@HistoricMinDate <= ct.TranDate AND ct.TranDate <= @HistoricMaxDate
	GROUP BY c.BrandID,
			c.CINID
	
	CREATE CLUSTERED INDEX cix_BrandID_CINID ON #Historic (CINID,BrandID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- #Historic', @time OUTPUT

	-- Find Future Transactions for Acquire, Lapsed & Shopper
	IF OBJECT_ID('tempdb..#Future') IS NOT NULL DROP TABLE #Future
	SELECT	cc.BrandID,
			c.CINID,
			SUM(ct.Amount) AS Sales,
			COUNT(ct.Amount) AS Frequency
	INTO	#Future
	FROM	Warehouse.Relational.ConsumerTransaction_MyRewards ct WITH (NOLOCK)
	JOIN	#CC cc
		ON	ct.ConsumerCombinationID = cc.ConsumerCombinationID
	JOIN	#Customer c
		ON	ct.CINID = c.CINID
	WHERE	0 < ct.Amount
		AND	@FutureMinDate <= ct.TranDate AND ct.TranDate <= @FutureMaxDate
	GROUP BY cc.BrandID,
			c.CINID
	
	CREATE CLUSTERED INDEX cix_BrandID_CINID ON #Future (CINID,BrandID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- #Future', @time OUTPUT

	-- Approx 20 minutes to this point

	--------------------------------------------------------------------------------------------
	-- Scoring // Deciling

	-- Lapsed / Shopper

	IF OBJECT_ID('tempdb..#SegmentToScore') IS NOT NULL DROP TABLE #SegmentToScore
	SELECT	a.BrandID,
			a.CINID,
			a.CurrentSegmentation,
			b.Sales,
			b.Frequency
	INTO	#SegmentToScore
	FROM	#InitialSegmentation a
	JOIN	#Historic b
		ON	a.BrandID = b.BrandID
		AND	a.CINID = b.CINID

	CREATE CLUSTERED INDEX cix_BrandID_CINID_CurrentSegmentation ON #SegmentToScore (CINID,BrandID,CurrentSegmentation)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- #SegmentToScore', @time OUTPUT
	-- 1m 8sec

	IF OBJECT_ID('tempdb..#NTILED') IS NOT NULL DROP TABLE #NTILED
	SELECT	BrandID,
			CINID,
			CurrentSegmentation,
			NTILE(10) OVER (PARTITION BY BrandID, CurrentSegmentation ORDER BY Sales DESC) AS Ranking,
			Sales,
			Frequency
	INTO	#NTILED
	FROM	#SegmentToScore

	CREATE CLUSTERED INDEX cix_BrandID_CINID ON #NTILED (BrandID, CINID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- #NTILED', @time OUTPUT
	-- 6m 0sec

	-- Approx 30 minutes to this point
	--------------------------------------------------------------------------------------------
	-- Acquire

	IF OBJECT_ID('tempdb..#CrossJoin') IS NOT NULL DROP TABLE #CrossJoin
	SELECT	b.BrandID,
			c.CINID,
			c.ComboID,
			hm.HeatmapIndex,
			BrandCount = CAST(COUNT(*) OVER (PARTITION BY b.BrandID) AS FLOAT)
	INTO	#CrossJoin
	FROM	#BaseCombo c
	CROSS JOIN #Brand b
	JOIN	Warehouse.Relational.HeatmapScore_POS hm
		ON	b.BrandID = hm.BrandID
		AND c.ComboID = hm.ComboID
	WHERE	NOT EXISTS
		(	SELECT	1
			FROM	#CustomerDates cd
			WHERE	c.CINID = cd.CINID
				AND	b.BrandID = cd.BrandID	)

	CREATE CLUSTERED INDEX nix_BrandID__HeatmapIndex ON #CrossJoin (BrandID, HeatmapIndex DESC)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS --  #CrossJoin', @time OUTPUT

	-- 18m 52s

	IF OBJECT_ID('tempdb..#Acquire') IS NOT NULL DROP TABLE #Acquire
	SELECT	a.BrandID,
			a.CINID,
			Ranking = CEILING(ROW_NUMBER() OVER (PARTITION BY a.BrandID ORDER BY a.HeatmapIndex DESC) / (a.BrandCount / 10))
	INTO	#Acquire
	FROM	#CrossJoin a 

	CREATE CLUSTERED INDEX cix_BrandID_CINID ON #Acquire (BrandID, CINID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- #Acquire', @time OUTPUT

	-- 10m

	--------------------------------------------------------------------------------------------
	-- Drivetime

	IF OBJECT_ID('tempdb..#Partner') IS NOT NULL DROP TABLE #Partner
	SELECT	br.BrandID,
			br.BrandName,
			p.PartnerID
	INTO	#Partner
	FROM	#Brand br
	JOIN	Warehouse.Relational.Partner p
		ON	br.BrandID = p.BrandID

	CREATE CLUSTERED INDEX cix_PartnerID ON #Partner (PartnerID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- #Partner', @time OUTPUT

	IF OBJECT_ID('tempdb..#StoreLocation') IS NOT NULL DROP TABLE #StoreLocation
	SELECT	o.PostalSector,
			b.BrandID
	INTO	#StoreLocation
	FROM	Warehouse.Relational.Outlet o
	JOIN	SLC_Report.dbo.RetailOutlet ro 
		ON	o.OutletID = ro.ID
	JOIN	#Partner b
		ON	ro.PartnerID = b.PartnerID
	WHERE	ro.SuppressFromSearch = 0
		AND	o.Region IS NOT NULL

	CREATE CLUSTERED INDEX cix_PostalSector ON #StoreLocation (PostalSector)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- #StoreLocation', @time OUTPUT

	IF OBJECT_ID('tempdb..#WithinDrivetime') IS NOT NULL DROP TABLE #WithinDriveTime
	SELECT	sl.BrandID,
			dtm.ToSector AS PostalSector,
			MIN(DriveTimeMins) AS DriveTime
	INTO	#WithinDrivetime
	FROM	#StoreLocation sl
	JOIN	Warehouse.Relational.DriveTimeMatrix dtm
		ON	sl.PostalSector = dtm.FromSector
	GROUP BY sl.BrandID,
			dtm.ToSector

	CREATE CLUSTERED INDEX cix_BrandID_PostalSector ON #WithinDrivetime (BrandID, PostalSector)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- #WithinDriveTime', @time OUTPUT

	--------------------------------------------------------------------------------------------
	-- Lapsed Shopper

	IF OBJECT_ID('tempdb..#LapsedShopper_Pop') IS NOT NULL DROP TABLE #LapsedShopper_Pop
	SELECT	n.BrandID,
			CASE
			  WHEN n.CurrentSegmentation = 8 THEN 'Lapsed'
			  WHEN n.CurrentSegmentation = 9 THEN 'Shopper'
			  ELSE 'Error'
			END AS Shopper_Segment,
			Ranking AS Deciles,
			b.Gender,
			b.Age_Group,
			b.Social_Class,
			b.MarketableByEmail,
			CASE
			  WHEN dt.DriveTime <= 25 THEN '01. Within 25 mins'
			  WHEN 25 < dt.DriveTime THEN '02.More than 25 mins'
			  ELSE '03. Unknown'
			END AS DriveTimeBand,
			COUNT(n.CINID) AS Population
	INTO	#LapsedShopper_Pop
	FROM	#Ntiled n
	JOIN	#Base b
		ON	n.CINID = b.CINID
	LEFT JOIN #WithinDrivetime dt
		ON	n.BrandID = dt.BrandID
		AND	b.PostalSector = dt.PostalSector
	GROUP BY n.BrandID,
			CASE
			  WHEN n.CurrentSegmentation = 8 THEN 'Lapsed'
			  WHEN n.CurrentSegmentation = 9 THEN 'Shopper'
			  ELSE 'Error'
			END ,
			Ranking ,
			b.Gender,
			b.Age_Group,
			b.Social_Class,
			b.MarketableByEmail,
			CASE
			  WHEN dt.DriveTime <= 25 THEN '01. Within 25 mins'
			  WHEN 25 < dt.DriveTime THEN '02.More than 25 mins'
			  ELSE '03. Unknown'
			END

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- #LapsedShopper_Pop', @time OUTPUT

	IF OBJECT_ID('tempdb..#LapsedShopper_Trans') IS NOT NULL DROP TABLE #LapsedShopper_Trans
	SELECT	n.BrandID,
			CASE
			  WHEN n.CurrentSegmentation = 8 THEN 'Lapsed'
			  WHEN n.CurrentSegmentation = 9 THEN 'Shopper'
			  ELSE 'Error'
			END AS Shopper_Segment,
			Ranking AS Deciles,
			b.Gender,
			b.Age_Group,
			b.Social_Class,
			b.MarketableByEmail,
			CASE
			  WHEN dt.DriveTime <= 25 THEN '01. Within 25 mins'
			  WHEN 25 < dt.DriveTime THEN '02.More than 25 mins'
			  ELSE '03. Unknown'
			END AS DriveTimeBand,
			COUNT(DISTINCT ft.CINID) AS Spenders,
			SUM(ft.Sales) AS Sales,
			SUM(ft.Frequency) AS Frequency
	INTO	#LapsedShopper_Trans
	FROM	#Ntiled n
	JOIN	#Future ft
		ON	n.CINID = ft.CINID
		AND n.BrandID = ft.BrandID
	JOIN	#Base b
		ON	n.CINID = b.CINID
	LEFT JOIN #WithinDrivetime dt
		ON	n.BrandID = dt.BrandID
		AND	b.PostalSector = dt.PostalSector
	GROUP BY n.BrandID,
			CASE
			  WHEN n.CurrentSegmentation = 8 THEN 'Lapsed'
			  WHEN n.CurrentSegmentation = 9 THEN 'Shopper'
			  ELSE 'Error'
			END ,
			Ranking ,
			b.Gender,
			b.Age_Group,
			b.Social_Class,
			b.MarketableByEmail,
			CASE
			  WHEN dt.DriveTime <= 25 THEN '01. Within 25 mins'
			  WHEN 25 < dt.DriveTime THEN '02.More than 25 mins'
			  ELSE '03. Unknown'
			END

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- #LapsedShopper_Trans', @time OUTPUT
	
	IF OBJECT_ID('tempdb..#LapsedShopper') IS NOT NULL DROP TABLE #LapsedShopper
	SELECT	a.*,
			b.Spenders,
			b.Sales,
			b.Frequency
	INTO	#LapsedShopper
	FROM	#LapsedShopper_Pop a
	LEFT JOIN	#LapsedShopper_Trans b
		ON	a.BrandID = b.BrandID
		AND	a.Shopper_Segment = b.Shopper_Segment
		AND	a.Deciles = b.Deciles
		AND a.Gender = b.Gender
		AND a.Age_Group = b.Age_Group
		AND	a.Social_Class = b.Social_Class
		AND a.MarketableByEmail = b.MarketableByEmail
		AND a.DriveTimeBand = b.DriveTimeBand
	
	CREATE CLUSTERED INDEX cix_BrandID_ShopperSegment ON #LapsedShopper (BrandID, Shopper_Segment)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- #LapsedShopper', @time OUTPUT

	IF OBJECT_ID('tempdb..#LapsedShopperTotals') IS NOT NULL DROP TABLE #LapsedShopperTotals
	SELECT	BrandID,
			Shopper_Segment,
			SUM(Population) AS TotalPopulation,
			SUM(Spenders) AS TotalSpenders,
			SUM(Sales) AS TotalSales,
			SUM(Frequency) AS TotalFrequency
	INTO	#LapsedShopperTotals
	FROM	#LapsedShopper
	GROUP BY BrandID,
			Shopper_Segment

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- #LapsedShopperTotals', @time OUTPUT

	-----------------------------------------------------
	-- LapsedShopper Output

	IF OBJECT_ID('tempdb..#LapsedShopperOutput') IS NOT NULL DROP TABLE #LapsedShopperOutput
	SELECT	'RBS' AS Publisher,
			a.BrandID,
			a.Shopper_Segment,
			a.Deciles,
			a.Gender,
			a.Age_Group,
			a.Social_Class,
			a.MarketableByEmail,
			a.DriveTimeBand,
			CAST(ROUND(COALESCE((1.0*Population)/NULLIF(TotalPopulation,0),0),11) AS DECIMAL(12,11)) AS ProportionOfCardholders,
			CAST(ROUND(COALESCE((1.0*Spenders)/NULLIF(TotalSpenders,0),0),11) AS DECIMAL(12,11)) AS ProportionOfSpenders,
			CAST(ROUND(COALESCE((1.0*Sales)/NULLIF(TotalSales,0),0),11) AS DECIMAL(12,11)) AS ProportionOfSpend,
			CAST(ROUND(COALESCE((1.0*Frequency)/NULLIF(TotalFrequency,0),0),11) AS DECIMAL(12,11)) AS ProportionOfTrans
	INTO	#LapsedShopperOutput
	FROM	#LapsedShopper a
	JOIN	#LapsedShopperTotals b
		ON	a.BrandID = b.BrandID
		AND a.Shopper_Segment = b.Shopper_Segment

	--------------------------------------------------------------------------------------------
	-- Acquire

	IF OBJECT_ID('tempdb..#Acquire_Pop') IS NOT NULL DROP TABLE #Acquire_Pop
	SELECT	n.BrandID,
			'Acquire' AS Shopper_Segment,
			Ranking AS Deciles,
			b.Gender,
			b.Age_Group,
			b.Social_Class,
			b.MarketableByEmail,
			CASE
			  WHEN dt.DriveTime <= 25 THEN '01. Within 25 mins'
			  WHEN 25 < dt.DriveTime THEN '02.More than 25 mins'
			  ELSE '03. Unknown'
			END AS DriveTimeBand,
			COUNT(n.CINID) AS Population
	INTO	#Acquire_Pop
	FROM	#Acquire n
	JOIN	#Base b
		ON	n.CINID = b.CINID
	LEFT JOIN #WithinDrivetime dt
		ON	n.BrandID = dt.BrandID
		AND	b.PostalSector = dt.PostalSector
	GROUP BY n.BrandID,
			Ranking ,
			b.Gender,
			b.Age_Group,
			b.Social_Class,
			b.MarketableByEmail,
			CASE
			  WHEN dt.DriveTime <= 25 THEN '01. Within 25 mins'
			  WHEN 25 < dt.DriveTime THEN '02.More than 25 mins'
			  ELSE '03. Unknown'
			END

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- #Acquire_Pop', @time OUTPUT

	IF OBJECT_ID('tempdb..#Acquire_Trans') IS NOT NULL DROP TABLE #Acquire_Trans
	SELECT	n.BrandID,
			'Acquire' AS Shopper_Segment,
			Ranking AS Deciles,
			b.Gender,
			b.Age_Group,
			b.Social_Class,
			b.MarketableByEmail,
			CASE
			  WHEN dt.DriveTime <= 25 THEN '01. Within 25 mins'
			  WHEN 25 < dt.DriveTime THEN '02.More than 25 mins'
			  ELSE '03. Unknown'
			END AS DriveTimeBand,
			COUNT(DISTINCT ft.CINID) AS Spenders,
			SUM(ft.Sales) AS Sales,
			SUM(ft.Frequency) AS Frequency
	INTO	#Acquire_Trans
	FROM	#Acquire n
	JOIN	#Future ft
		ON	n.CINID = ft.CINID
		AND n.BrandID = ft.BrandID
	JOIN	#Base b
		ON	n.CINID = b.CINID
	LEFT JOIN #WithinDrivetime dt
		ON	n.BrandID = dt.BrandID
		AND	b.PostalSector = dt.PostalSector
	GROUP BY n.BrandID,
			Ranking ,
			b.Gender,
			b.Age_Group,
			b.Social_Class,
			b.MarketableByEmail,
			CASE
			  WHEN dt.DriveTime <= 25 THEN '01. Within 25 mins'
			  WHEN 25 < dt.DriveTime THEN '02.More than 25 mins'
			  ELSE '03. Unknown'
			END

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- #Acquire_Trans', @time OUTPUT
	
	IF OBJECT_ID('tempdb..#Acquired') IS NOT NULL DROP TABLE #Acquired
	SELECT	a.*,
			b.Spenders,
			b.Sales,
			b.Frequency
	INTO	#Acquired
	FROM	#Acquire_Pop a
	LEFT JOIN	#Acquire_Trans b
		ON	a.BrandID = b.BrandID
		AND	a.Shopper_Segment = b.Shopper_Segment
		AND	a.Deciles = b.Deciles
		AND a.Gender = b.Gender
		AND a.Age_Group = b.Age_Group
		AND	a.Social_Class = b.Social_Class
		AND a.MarketableByEmail = b.MarketableByEmail
		AND a.DriveTimeBand = b.DriveTimeBand
	
	CREATE CLUSTERED INDEX cix_BrandID_ShopperSegment ON #Acquired (BrandID, Shopper_Segment)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- #Acquired', @time OUTPUT

	IF OBJECT_ID('tempdb..#AcquireTotals') IS NOT NULL DROP TABLE #AcquireTotals
	SELECT	BrandID,
			Shopper_Segment,
			SUM(Population) AS TotalPopulation,
			SUM(Spenders) AS TotalSpenders,
			SUM(Sales) AS TotalSales,
			SUM(Frequency) AS TotalFrequency
	INTO	#AcquireTotals
	FROM	#Acquired
	GROUP BY BrandID,
			Shopper_Segment

	CREATE CLUSTERED INDEX cix_BrandID_ShopperSegment ON #AcquireTotals (BrandID, Shopper_Segment)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- #AcquiredTotals', @time OUTPUT

	-----------------------------------------------------
	-- LapsedShopper Output

	IF OBJECT_ID('tempdb..#AcquireOutput') IS NOT NULL DROP TABLE #AcquireOutput
	SELECT	'RBS' AS Publisher,
			a.BrandID,
			a.Shopper_Segment,
			a.Deciles,
			a.Gender,
			a.Age_Group,
			a.Social_Class,
			a.MarketableByEmail,
			a.DriveTimeBand,
			CAST(ROUND(COALESCE((1.0*Population)/NULLIF(TotalPopulation,0),0),11) AS DECIMAL(12,11)) AS ProportionOfCardholders,
			CAST(ROUND(COALESCE((1.0*Spenders)/NULLIF(TotalSpenders,0),0),11) AS DECIMAL(12,11)) AS ProportionOfSpenders,
			CAST(ROUND(COALESCE((1.0*Sales)/NULLIF(TotalSales,0),0),11) AS DECIMAL(12,11)) AS ProportionOfSpend,
			CAST(ROUND(COALESCE((1.0*Frequency)/NULLIF(TotalFrequency,0),0),11) AS DECIMAL(12,11)) AS ProportionOfTrans
	INTO	#AcquireOutput
	FROM	#Acquired a
	JOIN	#AcquireTotals b
		ON	a.BrandID = b.BrandID
		AND a.Shopper_Segment = b.Shopper_Segment

	-- Clear previously held data
	IF @BrandList IS NULL
		BEGIN
			TRUNCATE TABLE Warehouse.ExcelQuery.ROCEFT_RBSCumulativeGains
		END
	ELSE
		BEGIN
			DELETE FROM Warehouse.ExcelQuery.ROCEFT_RBSCumulativeGains
			WHERE CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0
		END

	-- Insert New Outputs
	INSERT INTO Warehouse.ExcelQuery.ROCEFT_RBSCumulativeGains
		SELECT * FROM #LapsedShopperOutput
		UNION
		SELECT * FROM #AcquireOutput

	EXEC Prototype.oo_TimerMessage 'ROCEFT - CumulativeGainsRBS -- Finish', @time OUTPUT
END