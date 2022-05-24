-- =============================================
-- Author:		<Shaun Hide>
-- Create date: <23rd July 2018>
-- Description:	<MVP - Engagement Scores>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[MVP_Engagement_Calculate]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	DECLARE @time DATETIME
	DECLARE @msg VARCHAR(2048)
	
	EXEC Prototype.oo_TimerMessage 'Start Execution', @time OUTPUT

	-- Turn Off the index --
	ALTER INDEX nix_ComboID ON Warehouse.ExcelQuery.MVP_Engagement DISABLE
	ALTER INDEX nix_ComboID2 ON Warehouse.ExcelQuery.MVP_Engagement DISABLE

	EXEC Prototype.oo_TimerMessage 'Turn Off Indexes', @time OUTPUT

	-- Clear up historics that are no longer needed
	DECLARE @MinCycleStart DATE = (SELECT MIN(CycleStart) FROM	Warehouse.ExcelQuery.MVP_DateTable WHERE EngagementFlaggedDate = 1)
	DELETE FROM Warehouse.ExcelQuery.MVP_Engagement WHERE CycleStart < @MinCycleStart

	EXEC Prototype.oo_TimerMessage 'Delete Unnecessary Data', @time OUTPUT

	-- Find all customers historically
	IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
	SELECT	c.FanID,
			cin.CINID,
			c.ActivatedDate,
			c.DeactivatedDate,
			c.ComboID
	INTO	#Customers
	FROM   (SELECT	a.*,
					b.ComboID,
					cast(NULL as varchar(30)) as MarketableByEmail,
					cast(NULL as varchar(30)) as EngagementCat_LowFreq,
					cast(NULL as varchar(30)) as EngagementCat_HighFreq
			FROM   (
					SELECT FanID,
							SourceUID,
							ActivatedDate,
							DeactivatedDate,
							Gender,
							CASE	
								WHEN AgeCurrent < 18 OR AgeCurrent IS NULL THEN '99. Unknown'
								WHEN AgeCurrent BETWEEN 18 AND 24 THEN '01. 18 to 24'
								WHEN AgeCurrent BETWEEN 25 AND 29 THEN '02. 25 to 29'
								WHEN AgeCurrent BETWEEN 30 AND 39 THEN '03. 30 to 39'
								WHEN AgeCurrent BETWEEN 40 AND 49 THEN '04. 40 to 49'
								WHEN AgeCurrent BETWEEN 50 AND 59 THEN '05. 50 to 59'
								WHEN AgeCurrent BETWEEN 60 AND 64 THEN '06. 60 to 64'
								WHEN AgeCurrent >= 65 THEN '07. 65+' 
							END AS Age_Group
							,isnull((cam.[CAMEO_CODE_GROUP] +'-'+ camg.CAMEO_CODE_GROUP_Category),'99. Unknown') as CAMEO_CODE_GRP
					FROM	Warehouse.Relational.Customer c WITH (NOLOCK) 
					LEFT JOIN Warehouse.Relational.CAMEO cam WITH (NOLOCK)  on cam.postcode = c.postcode
					LEFT JOIN Warehouse.Relational.cameo_code_group camG WITH (NOLOCK)  on camG.CAMEO_CODE_GROUP =cam.CAMEO_CODE_GROUP
				   ) a
			LEFT JOIN Warehouse.InsightArchive.HM_Combo_SalesSTO_Tool b
				ON	a.gender=b.gender 
				AND a.CAMEO_CODE_GRP=b.CAMEO_grp 
				AND a.Age_Group=b.Age_Group
			) c
	JOIN	Warehouse.Relational.CINList cin
		ON	c.SourceUID = cin.CIN
	WHERE	NOT EXISTS
			(
				SELECT	*
				FROM	Warehouse.Staging.Customer_DuplicateSourceUID dup
				WHERE	EndDate IS NULL
					AND c.SourceUID = dup.SourceUID
			)

	CREATE NONCLUSTERED INDEX nix_ActivatedDate ON #Customers(ActivatedDate)
	CREATE NONCLUSTERED INDEX nix_DeactivatedDate ON #Customers(DeactivatedDate)
	
	EXEC Prototype.oo_TimerMessage '#Customers', @time OUTPUT

	-- SELECT TOP 10 * FROM #Customers

	--  Find any outstanding dates to classify
	IF OBJECT_ID('tempdb..#EngagementDates') IS NOT NULL DROP TABLE #EngagementDates
	SELECT	DATEADD(MONTH,-6,CycleStart) AS EngagementMetricStartDate,
			DATEADD(DAY,-1,CycleStart) AS EngagementMetricEndDate,
			CycleStart,
			CycleEnd,
			ROW_NUMBER() OVER (ORDER BY CycleStart ASC) AS RowNo
	INTO	#EngagementDates
	FROM	Warehouse.ExcelQuery.MVP_DateTable dt
	WHERE	EngagementFlaggedDate = 1

	DELETE	a
	FROM	#EngagementDates a
	WHERE	CycleStart IN 
		  ( SELECT	DISTINCT CycleStart
			FROM	Warehouse.ExcelQuery.MVP_Engagement)

	EXEC Prototype.oo_TimerMessage '#EngagementDates', @time OUTPUT

	-- SELECT * FROM #EngagementDates

	DECLARE @i INT = (SELECT MIN(RowNo) FROM #EngagementDates)
	DECLARE @EngagementMetricStartDate DATE
	DECLARE @EngagementMetricEndDate DATE
	DECLARE @CycleStart DATE

	WHILE @i <= (SELECT MAX(RowNo) FROM #EngagementDates)
		BEGIN
			SELECT	@EngagementMetricStartDate = EngagementMetricStartDate,
					@EngagementMetricEndDate = EngagementMetricEndDate,
					@CycleStart = CycleStart
			FROM	#EngagementDates
			WHERE	RowNo = @i

			-- Create a Cycle CustomerMetrics Table
			IF OBJECT_ID('tempdb..#CustomerMetrics') IS NOT NULL DROP TABLE #CustomerMetrics
			CREATE TABLE #CustomerMetrics
				(
					CycleStart DATE,
					FanID INT,
					CINID INT,
					ComboID INT,
					MarketableByEmail BIT,
					EmailOpens INT,
					WebLogins INT,
					EngagementScore FLOAT,
					EngagementRank INT
				)

			-- Find All Live Customers @ EngagementMetricEndDate
			INSERT INTO	#CustomerMetrics
				SELECT	@CycleStart,
						c.FanID,
						c.CINID,
						c.ComboID,
						0,
						0,
						0,
						0,
						0
				FROM	#Customers c
				WHERE	ActivatedDate < @CycleStart
					AND	(@CycleStart <= DeactivatedDate OR DeactivatedDate IS NULL)

			CREATE CLUSTERED INDEX cix_FanID ON #CustomerMetrics (FanID)

			EXEC Prototype.oo_TimerMessage '#CustomerMetrics', @time OUTPUT
		
			-- Find MarketableByEmail at that point in time
			UPDATE c
			SET	   MarketableByEmail = mbe.MarketableByEmail	
			FROM   #CustomerMetrics c
			JOIN  
				(	SELECT	a.FanID,
							a.MarketableByEmail
					FROM	Warehouse.Relational.Customer_MarketableByEmailStatus a
					JOIN	#CustomerMetrics b
						ON	a.FanID = b.FanID
					WHERE	StartDate <= @EngagementMetricEndDate
						AND	(EndDate IS NULL OR @EngagementMetricEndDate < EndDate)
				) mbe
				ON	mbe.FanID = c.FanID

			EXEC Prototype.oo_TimerMessage '#Marketable', @time OUTPUT

			-- Find Email Opens

			IF OBJECT_ID('tempdb..#EmailOpens') IS NOT NULL DROP TABLE #EmailOpens
			SELECT 	ee.FanID,
					COUNT(DISTINCT ee.CampaignKey) AS EmailOpens
			INTO	#EmailOpens
			FROM	Warehouse.Relational.EmailEvent ee -- List of Events
			JOIN	(
						SELECT	DISTINCT CampaignKey
						FROM	Warehouse.Relational.EmailCampaign
						WHERE	CampaignName LIKE '%NEWSLETTER%'
							AND CampaignName NOT LIKE '%COPY%' 
							AND CampaignName NOT LIKE '%TEST%'
					) cls -- List of Newsletter emails
				ON	ee.CampaignKey = cls.CampaignKey
			JOIN	#CustomerMetrics c
				ON	ee.FanID = c.FanID
			WHERE	ee.EmailEventCodeID IN (
											1301 -- Email Open
											,605  -- Link Click
											)
				AND	@EngagementMetricStartDate <= EventDate AND EventDate <= @EngagementMetricEndDate
			GROUP BY ee.FanID

			CREATE CLUSTERED INDEX cix_FanID ON #EmailOpens (FanID)

			UPDATE c
			SET	   EmailOpens = ee.EmailOpens
			FROM   #CustomerMetrics c
			JOIN	#EmailOpens ee
			   ON  c.FanID = ee.FanID

			EXEC Prototype.oo_TimerMessage '#EmailOpens', @time OUTPUT

			-- Find Web Logins

			UPDATE c
			SET	   WebLogins = wl.WebLogins
			FROM   #CustomerMetrics c
			JOIN
				(	SELECT	a.FanID,
							COUNT(DISTINCT CAST(TrackDate AS DATE)) AS WebLogins
					FROM	Warehouse.Relational.WebLogins a
					JOIN	#CustomerMetrics b
						ON	a.FanID = b.FanID
					WHERE	(@EngagementMetricStartDate <= TrackDate AND TrackDate <= @EngagementMetricEndDate)
					GROUP BY a.FanID
				)	wl
			   ON  c.FanID = wl.FanID

			EXEC Prototype.oo_TimerMessage '#WebLogins', @time OUTPUT

			-- Derive EngagementScore

			UPDATE	c
			SET		EngagementScore = 2 * WebLogins + EmailOpens
			FROM	#CustomerMetrics c

			EXEC Prototype.oo_TimerMessage '#EngagementScore', @time OUTPUT

			-- Determine Engagement Category

			UPDATE	c
			SET		EngagementRank =
						CASE
						  WHEN b.FanID IS NULL THEN
							CASE
							  WHEN MarketableByEmail = 0 THEN 4
							  ELSE 3
							END
						  ELSE NTILEScore
						END
			FROM	#CustomerMetrics c
			LEFT JOIN	(	SELECT	FanID,
								NTILE(2) OVER (ORDER BY EngagementScore DESC) AS NTILEScore
						FROM	#CustomerMetrics
						WHERE	EngagementScore != 0 ) b
				ON	b.FanID = c.FanID

			EXEC Prototype.oo_TimerMessage '#EngagementRank', @time OUTPUT

			-- Store
			INSERT INTO Warehouse.ExcelQuery.MVP_Engagement
				SELECT	*
				FROM	#CustomerMetrics
		 
			 EXEC Prototype.oo_TimerMessage '#Insertion', @time OUTPUT
		
			-- Iterate
			SET @i = @i + 1
		END

	-- Turn On and Rebuild Index --
	ALTER INDEX ALL ON Warehouse.ExcelQuery.MVP_Engagement REBUILD

END