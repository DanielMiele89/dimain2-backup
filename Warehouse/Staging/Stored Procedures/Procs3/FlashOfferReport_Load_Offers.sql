/******************************************************************************
Author: Jason Shipp
Created: 23/05/2018
Purpose: 
	- Loads Warehouse, nFI and AMEX offers active for at least one day in a given analysis period for a given retailer into Warehouse.Staging.FlashOfferReport_All_Offers
	- Loads the ConsumerCombinations for the partner being reported on into Warehouse.Staging.FlashOfferReport_ConsumerCombinations

Notes:
	- Stored procedure triggered by the Warehouse.Staging.FlashOfferReport_Load_Offers_Trigger stored procedure
	
------------------------------------------------------------------------------
Modification History

Jason Shipp 25/06/2018
	- Expanded query to generate daily and weekly analysis periods, as well as cumulative
	- Changed logic so only new analysis periods for Iron Offers are loaded into Warehouse.Staging.FlashOfferReport_All_Offers

Jason Shipp 05/03/2019
	- Added ability to identify partners by their PartnerID(s)

03/04/2019 Jason Shipp
    - Referenced PublisherID in nFI.Relational.AmexOffer instead of hardcoding -1

******************************************************************************/
CREATE PROCEDURE Staging.FlashOfferReport_Load_Offers (
	@RetailerNamePartialName VARCHAR(50) -- String identifying retailer to analyse (enough of retailer name to uniquely identify)
	, @PartnerID varchar(MAX) = NULL -- String of PartnerIDs, separated by commas or newlines: use this if partner needs to be specifically identified by its PartnerIDs, otherwise leave NULL
	, @StartDate DATE = NULL -- Analysis start date (default to offer setup start date)
	, @EndDate DATE = NULL -- Analysis end date (default to yesterday)
)
	
AS
BEGIN
	
	SET NOCOUNT ON;

	----For testing
	--DECLARE @RetailerNamePartialName VARCHAR(50) = 'Morrisons'
	--DECLARE @PartnerID varchar(MAX) = 4263
	--DECLARE @StartDate DATE = '2019-03-14'
	--DECLARE @EndDate DATE = NULL

	SET @PartnerID = REPLACE(REPLACE(@PartnerID, CHAR(13) + CHAR(10), ','), ', ', ',');

	/******************************************************************************
	Load partner alternates
	******************************************************************************/

	IF OBJECT_ID('tempdb..#PartnerAlternate') IS NOT NULL DROP TABLE #PartnerAlternate;

	SELECT DISTINCT * 
	INTO #PartnerAlternate
	FROM 
		(SELECT 
		PartnerID
		, AlternatePartnerID
		FROM Warehouse.APW.PartnerAlternate

		UNION ALL  

		SELECT 
		PartnerID
		, AlternatePartnerID
		FROM nFI.APW.PartnerAlternate
		) x;

	/******************************************************************************
	Load retailer offers to analyse
	******************************************************************************/

	IF OBJECT_ID('tempdb..#AllOffers') IS NOT NULL DROP TABLE #AllOffers;

	-- nFI out of programme offers 
	SELECT DISTINCT
		[io].ID AS IronOfferID
		, COALESCE(@StartDate, CAST([io].StartDate AS DATE)) AS StartDate
		, COALESCE(@EndDate, CAST(DATEADD(day, -1, GETDATE()) AS date)) AS EndDate
		, CAST([io].StartDate AS date) AS OfferSetupStartDate
		, CAST([io].EndDate AS date) AS OfferSetupEndDate
		, CAST(cyc.StartDate AS date) AS IOCycleStartDate
		, CAST(cyc.EndDate AS date) AS IOCycleEndDate
		, [io].IronOfferName
		, COALESCE(pa.AlternatePartnerID, [io].PartnerID) AS PartnerID
		, [io].PartnerID AS SubPartnerID
		, p.PartnerName
		, ior.ClubID
		, 0 AS IsWarehouse
		, ior.ironoffercyclesid
		, ioc.controlgroupid
		, ior.SpendStretch
		, 0 AS ControlGroupTypeID
		, 'Cumulative' AS PeriodType
	INTO #AllOffers
	FROM nFI.Relational.IronOffer_References ior
	LEFT JOIN nFI.Relational.IronOffer [io]
		ON ior.IronOfferID = [io].ID
	INNER JOIN nFI.Relational.ironoffercycles ioc
		ON ior.ironoffercyclesid = ioc.ironoffercyclesid
	INNER JOIN nFI.Relational.OfferCycles cyc
		ON ioc.offercyclesid = cyc.OfferCyclesID
	LEFT JOIN #PartnerAlternate pa
		ON [io].PartnerID = pa.PartnerID
	LEFT JOIN nFI.Relational.[Partner] p
		ON COALESCE(pa.AlternatePartnerID, [io].PartnerID) = p.PartnerID
	WHERE 
		[io].IsSignedOff = 1
		AND [io].IronOfferName NOT LIKE '%Spare%'
		AND p.PartnerName LIKE '%' + @RetailerNamePartialName + '%'
		AND (@PartnerID IS NULL OR CHARINDEX(',' + CAST(p.PartnerID AS varchar) + ',', ',' + @PartnerID + ',') > 0)
		AND ( -- Offers overlapping analysis period
			([io].StartDate <= @EndDate OR @EndDate IS NULL)
			AND ([io].EndDate >= @StartDate OR [io].EndDate IS NULL OR @StartDate IS NULL)
		)
		AND ( -- Offer cycles overlapping analysis period
			(cyc.StartDate <= @EndDate OR @EndDate IS NULL)
			AND (cyc.EndDate >= @StartDate OR @StartDate IS NULL)
		)

	UNION

	-- nFI in programme offers 
	SELECT DISTINCT
		[io].ID AS IronOfferID
		, COALESCE(@StartDate, CAST([io].StartDate AS DATE)) AS StartDate
		, COALESCE(@EndDate, CAST(DATEADD(day, -1, GETDATE()) AS date)) AS EndDate
		, CAST([io].StartDate AS date) AS OfferSetupStartDate
		, CAST([io].EndDate AS date) AS OfferSetupEndDate
		, CAST(cyc.StartDate AS date) AS IOCycleStartDate
		, CAST(cyc.EndDate AS date) AS IOCycleEndDate
		, [io].IronOfferName
		, COALESCE(pa.AlternatePartnerID, [io].PartnerID) AS PartnerID
		, [io].PartnerID AS SubPartnerID
		, p.PartnerName
		, ior.ClubID
		, 0 AS IsWarehouse
		, ior.ironoffercyclesid
		, scg.controlgroupid
		, ior.SpendStretch
		, 1 AS ControlGroupTypeID
		, 'Cumulative' AS PeriodType
	FROM nFI.Relational.IronOffer_References ior
	LEFT JOIN nFI.Relational.IronOffer [io]
		ON ior.IronOfferID = [io].ID
	INNER JOIN nFI.Relational.ironoffercycles ioc
		ON ior.ironoffercyclesid = ioc.ironoffercyclesid
	INNER JOIN nFI.Relational.OfferCycles cyc
		ON ioc.offercyclesid = cyc.OfferCyclesID
	INNER JOIN nFI.Relational.SecondaryControlGroups scg
		ON scg.IronOfferCyclesID = ioc.ironoffercyclesid
	LEFT JOIN #PartnerAlternate pa
		ON [io].PartnerID = pa.PartnerID
	LEFT JOIN nFI.Relational.[Partner] p
		ON COALESCE(pa.AlternatePartnerID, [io].PartnerID) = p.PartnerID
	WHERE 
		[io].IsSignedOff = 1
		AND [io].IronOfferName NOT LIKE '%Spare%'
		AND p.PartnerName LIKE '%' + @RetailerNamePartialName + '%'
		AND (@PartnerID IS NULL OR CHARINDEX(',' + CAST(p.PartnerID AS varchar) + ',', ',' + @PartnerID + ',') > 0)
		AND ( -- Offers overlapping analysis period
			([io].StartDate <= @EndDate OR @EndDate IS NULL)
			AND ([io].EndDate >= @StartDate OR [io].EndDate IS NULL OR @StartDate IS NULL)
		)
		AND ( -- Offer cycles overlapping analysis period
			(cyc.StartDate <= @EndDate OR @EndDate IS NULL)
			AND (cyc.EndDate >= @StartDate OR @StartDate IS NULL)
		)

	UNION

	-- Warehouse out of programme offers
	SELECT DISTINCT
		[io].IronOfferID
		, COALESCE(@StartDate, CAST([io].StartDate AS DATE)) AS StartDate
		, COALESCE(@EndDate, CAST(DATEADD(day, -1, GETDATE()) AS date)) AS EndDate
		, CAST([io].StartDate AS date) AS OfferSetupStartDate
		, CAST([io].EndDate AS date) AS OfferSetupEndDate
		, CAST(cyc.StartDate AS date) AS IOCycleStartDate
		, CAST(cyc.EndDate AS date) AS IOCycleEndDate
		, [io].IronOfferName
		, COALESCE(pa.AlternatePartnerID, [io].PartnerID) AS PartnerID
		, [io].PartnerID AS SubPartnerID
		, p.PartnerName
		, ior.ClubID
		, 1 AS IsWarehouse
		, ior.ironoffercyclesid
		, ioc.controlgroupid
		, ior.SpendStretch
		, 0 AS ControlGroupTypeID
		, 'Cumulative' AS PeriodType
	FROM Warehouse.Relational.IronOffer_References ior
	LEFT JOIN Warehouse.Relational.IronOffer [io]
		ON ior.IronOfferID = [io].IronOfferID
	INNER JOIN Warehouse.Relational.ironoffercycles ioc
		ON ior.ironoffercyclesid = ioc.ironoffercyclesid
	INNER JOIN Warehouse.Relational.OfferCycles cyc
		ON ioc.offercyclesid = cyc.OfferCyclesID
	LEFT JOIN #PartnerAlternate pa
		ON [io].PartnerID = pa.PartnerID
	LEFT JOIN Warehouse.Relational.[Partner] p
		ON COALESCE(pa.AlternatePartnerID, [io].PartnerID) = p.PartnerID
	WHERE 
		[io].IsSignedOff = 1
		AND [io].IronOfferName NOT LIKE '%Spare%'
		AND p.PartnerName LIKE '%' + @RetailerNamePartialName + '%'
		AND (@PartnerID IS NULL OR CHARINDEX(',' + CAST(p.PartnerID AS varchar) + ',', ',' + @PartnerID + ',') > 0)
		AND ( -- Offers overlapping analysis period
			([io].StartDate <= @EndDate OR @EndDate IS NULL)
			AND ([io].EndDate >= @StartDate OR [io].EndDate IS NULL OR @StartDate IS NULL)
		)
		AND ( -- Offer cycles overlapping analysis period
			(cyc.StartDate <= @EndDate OR @EndDate IS NULL)
			AND (cyc.EndDate >= @StartDate OR @StartDate IS NULL)
		)

	UNION

	-- Warehouse in programme offers
	SELECT DISTINCT
		[io].IronOfferID
		, COALESCE(@StartDate, CAST([io].StartDate AS DATE)) AS StartDate
		, COALESCE(@EndDate, CAST(DATEADD(day, -1, GETDATE()) AS date)) AS EndDate
		, CAST([io].StartDate AS date) AS OfferSetupStartDate
		, CAST([io].EndDate AS date) AS OfferSetupEndDate
		, CAST(cyc.StartDate AS date) AS IOCycleStartDate
		, CAST(cyc.EndDate AS date) AS IOCycleEndDate
		, [io].IronOfferName
		, COALESCE(pa.AlternatePartnerID, [io].PartnerID) AS PartnerID
		, [io].PartnerID AS SubPartnerID
		, p.PartnerName
		, ior.ClubID
		, 1 AS IsWarehouse
		, ior.ironoffercyclesid
		, scg.controlgroupid
		, ior.SpendStretch
		, 1 AS ControlGroupTypeID
		, 'Cumulative' AS PeriodType
	FROM Warehouse.Relational.IronOffer_References ior
	LEFT JOIN Warehouse.Relational.IronOffer [io]
		ON ior.IronOfferID = [io].IronOfferID
	INNER JOIN Warehouse.Relational.ironoffercycles ioc
		ON ior.ironoffercyclesid = ioc.ironoffercyclesid
	INNER JOIN Warehouse.Relational.OfferCycles cyc
		ON ioc.offercyclesid = cyc.OfferCyclesID
	INNER JOIN Warehouse.Relational.SecondaryControlGroups scg
		ON ioc.ironoffercyclesid = scg.IronOfferCyclesID
	LEFT JOIN #PartnerAlternate pa
		ON [io].PartnerID = pa.PartnerID
	LEFT JOIN Warehouse.Relational.[Partner] p
		ON COALESCE(pa.AlternatePartnerID, [io].PartnerID) = p.PartnerID
	WHERE 
		[io].IsSignedOff = 1
		AND [io].IronOfferName NOT LIKE '%Spare%'
		AND p.PartnerName LIKE '%' + @RetailerNamePartialName + '%'
		AND (@PartnerID IS NULL OR CHARINDEX(',' + CAST(p.PartnerID AS varchar) + ',', ',' + @PartnerID + ',') > 0)
		AND ( -- Offers overlapping analysis period
			([io].StartDate <= @EndDate OR @EndDate IS NULL)
			AND ([io].EndDate >= @StartDate OR [io].EndDate IS NULL OR @StartDate IS NULL)
		)
		AND ( -- Offer cycles overlapping analysis period
			(cyc.StartDate <= @EndDate OR @EndDate IS NULL)
			AND (cyc.EndDate >= @StartDate OR @StartDate IS NULL)
		)

	UNION

	-- AMEX offers
	SELECT DISTINCT
		[io].IronOfferID
		, COALESCE(@StartDate, CAST([io].StartDate AS DATE)) AS StartDate
		, COALESCE(@EndDate, CAST(DATEADD(day, -1, GETDATE()) AS date)) AS EndDate		
		, CAST([io].StartDate AS date) AS OfferSetupStartDate
		, CAST([io].EndDate AS date) AS OfferSetupEndDate
		, CAST(cyc.StartDate AS date) AS IOCycleStartDate
		, CAST(cyc.EndDate AS date) AS IOCycleEndDate
		, [io].TargetAudience AS IronOfferName
		, COALESCE(pa.AlternatePartnerID, [io].RetailerID) AS PartnerID
		, [io].RetailerID AS SubPartnerID
		, p.PartnerName
		, [io].PublisherID AS ClubID -- Jason Shipp 03/04/2019
		, NULL AS IsWarehouse
		, NULL AS IronOfferCyclesID
		, ioc.AmexControlGroupID AS controlgroupid
		, [io].SpendStretch
		, 0 AS ControlGroupTypeID
		, 'Cumulative' AS PeriodType
	FROM nFI.Relational.AmexOffer [io]
	INNER JOIN nFI.Relational.AmexIronOfferCycles ioc
		ON [io].IronOfferID = ioc.AmexIronOfferID
	INNER JOIN nFI.Relational.OfferCycles cyc
		ON ioc.offercyclesid = cyc.OfferCyclesID
	LEFT JOIN #PartnerAlternate pa
		ON [io].RetailerID = pa.PartnerID
	LEFT JOIN nFI.Relational.[Partner] p
		ON COALESCE(pa.AlternatePartnerID, [io].RetailerID) = p.PartnerID
	WHERE 
		p.PartnerName LIKE '%' + @RetailerNamePartialName + '%'
		AND (@PartnerID IS NULL OR CHARINDEX(',' + CAST(p.PartnerID AS varchar) + ',', ',' + @PartnerID + ',') > 0)
		AND ( -- Offers overlapping analysis period
			([io].StartDate <= @EndDate OR @EndDate IS NULL)
			AND ([io].EndDate >= @StartDate OR [io].EndDate IS NULL OR @StartDate IS NULL)
		)
		AND ( -- Offer cycles overlapping analysis period
			(cyc.StartDate <= @EndDate OR @EndDate IS NULL)
			AND (cyc.EndDate >= @StartDate OR @StartDate IS NULL)
		);

	/******************************************************************************
	Load calendar table containing daily and weekly start and end dates within the analysis period
	******************************************************************************/

	SET DATEFIRST 1; -- Set Monday as the first day of the week

	DECLARE @Today DATE = CAST(GETDATE() AS DATE);
	DECLARE @MinStartDate date = (SELECT MIN(StartDate) FROM #AllOffers);
	DECLARE @MaxEndDate date = (SELECT MAX(EndDate) FROM #AllOffers);
	--DECLARE @DaysToReport int = 7;
	--DECLARE @CompleteWeeksToReport int = 1;

	IF OBJECT_ID('tempdb..#Calendar') IS NOT NULL DROP TABLE #Calendar;
	
	WITH 
       E1 AS (SELECT n = 0 FROM (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) d (n))
       , E2 AS (SELECT n = 0 FROM E1 a CROSS JOIN E1 b)
       , Tally AS (SELECT n = 0 UNION ALL SELECT n = ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) FROM E2 a CROSS JOIN E2 b) -- Create table of numbers
	   , TallyDates AS (SELECT n, CalDate = DATEADD(day, n, @MinStartDate) FROM Tally WHERE DATEADD(day, n, @MinStartDate) <= @MaxEndDate) -- Create table of consecutive dates
	
	SELECT
		c.CalDate AS StartDate
		, c.CalDate AS EndDate
		, 'Daily' AS PeriodType
	INTO #Calendar
	FROM TallyDates c
	--WHERE 
	--	c.CalDate >= DATEADD(day, -(@DaysToReport-1), @MaxEndDate)
		
	UNION ALL

	SELECT 
		StartDate
		, EndDate
		, PeriodType
	FROM (
		SELECT DISTINCT
			CASE 
				WHEN DATEADD(dd, -(DATEPART(dw, CalDate)-1), CalDate) < @MinStartDate
				THEN @MinStartDate -- Don't let StartDate go before analysis start date
				ELSE DATEADD(dd, -(DATEPART(dw, CalDate)-1), CalDate) 
			END	AS StartDate -- For each calendar date in #Dates, minus days since the most recent Monday  
			, DATEADD(dd, -(DATEPART(dw, CalDate)-1)+6, CalDate) AS EndDate -- For each calendar date in #Dates, minus days since the most recent Sunday
			, 'Weekly' AS PeriodType
		FROM TallyDates
		WHERE
			DATEADD(dd, -(DATEPART(dw, CalDate)-1)+6, CalDate) <= CalDate -- Only complete weeks
		UNION -- Load most recent week (may be partial); don't use UNION ALL to avoid duplication
		SELECT (DATEADD( -- 
			day
			, -(DATEPART(dw, DATEADD(day, -1, @Today)))+1
			, DATEADD(day, -1, @Today))
		) AS StartDate
		, DATEADD(day, -1, @Today) AS EndDate
		, 'Weekly' AS PeriodType
	) x
	--WHERE 
	--EndDate >= DATEADD(
	--	week
	--	, -(@CompleteWeeksToReport-1)
	--	, (SELECT DATEADD( -- Most recent Sunday
	--		day
	--		, -(DATEPART(dw, @Today))
	--		, @Today)
	--	)
	--);

	/******************************************************************************
	Load retailer offers to analyse, expanded to include daily, weekly and cumulative analysis periods not analysed before

	-- Create table for storing results:		

	CREATE TABLE Warehouse.Staging.FlashOfferReport_All_Offers (
		ID int IDENTITY (1, 1)
		, IronOfferID int NOT NULL
		, StartDate date NOT NULL
		, EndDate date NOT NULL
		, OfferSetupStartDate date NOT NULL
		, OfferSetupEndDate date
		, IOCycleStartDate date NOT NULL
		, IOCycleEndDate date NOT NULL
		, PeriodType varchar(25) NOT NULL
		, IronOfferName nvarchar(200)
		, PartnerID int
		, SubPartnerID int
		, PartnerName varchar(100)
		, ClubID int
		, IsWarehouse int
		, IronOfferCyclesID int
		, ControlGroupID int NOT NULL
		, SpendStretch money
		, ControlGroupTypeID int
		, CalculationDate date NOT NULL
		, CONSTRAINT PK_FlashOfferReport_All_Offers PRIMARY KEY CLUSTERED (ID)
		, CONSTRAINT AK_FlashOfferReport_All_Offers_IOC UNIQUE(IronOfferID, IronOfferCyclesID, ControlGroupTypeID, StartDate, EndDate, PeriodType) 
		, CONSTRAINT AK_FlashOfferReport_All_Offers_ControlGroup UNIQUE(IronOfferID, ControlGroupID, ControlGroupTypeID, StartDate, EndDate, PeriodType, IsWarehouse, IronOfferCyclesID)
	)
	CREATE NONCLUSTERED INDEX IX_FlashOfferReport_All_Offers ON Warehouse.Staging.FlashOfferReport_All_Offers (
		IronOfferID, IsWarehouse, ControlGroupTypeID, StartDate, EndDate, PeriodType
	)
	******************************************************************************/

	--TRUNCATE TABLE Warehouse.Staging.FlashOfferReport_All_Offers; -- Table cleared in trigger stored procedure
	
	INSERT INTO Warehouse.Staging.FlashOfferReport_All_Offers (
		IronOfferID
		, StartDate
		, EndDate
		, OfferSetupStartDate
		, OfferSetupEndDate
		, IOCycleStartDate
		, IOCycleEndDate
		, PeriodType
		, IronOfferName
		, PartnerID
		, SubPartnerID
		, PartnerName
		, ClubID
		, IsWarehouse
		, ironoffercyclesid
		, controlgroupid
		, SpendStretch
		, ControlGroupTypeID
		, CalculationDate
	)

	SELECT *
	FROM (
		-- Cumulative periods
		SELECT DISTINCT
			o.IronOfferID
			, o.StartDate
			, o.EndDate
			, o.OfferSetupStartDate
			, o.OfferSetupEndDate
			, o.IOCycleStartDate
			, o.IOCycleEndDate
			, o.PeriodType
			, o.IronOfferName
			, o.PartnerID
			, o.SubPartnerID
			, o.PartnerName
			, o.ClubID
			, o.IsWarehouse
			, o.ironoffercyclesid
			, o.controlgroupid
			, o.SpendStretch
			, o.ControlGroupTypeID
			, CAST(GETDATE() AS DATE) AS CalculationDate
		FROM #AllOffers o
	
		UNION ALL

		-- Daily and weekly periods
		SELECT
			o.IronOfferID
			, cal.StartDate
			, cal.EndDate
			, o.OfferSetupStartDate
			, o.OfferSetupEndDate
			, o.IOCycleStartDate
			, o.IOCycleEndDate
			, cal.PeriodType
			, o.IronOfferName
			, o.PartnerID
			, o.SubPartnerID
			, o.PartnerName
			, o.ClubID
			, o.IsWarehouse
			, o.ironoffercyclesid
			, o.controlgroupid
			, o.SpendStretch
			, o.ControlGroupTypeID
			, CAST(GETDATE() AS DATE) AS CalculationDate
		FROM #AllOffers o
		INNER JOIN #Calendar cal -- Expand table to include all analysis periods in calendar table
			ON cal.StartDate >= o.StartDate
			AND cal.EndDate <= o.EndDate
			AND o.IOCycleStartDate <= cal.EndDate -- Offer cycles overlapping analysis periods
			AND o.IOCycleEndDate >= cal.StartDate
	) o
	WHERE NOT EXISTS ( -- Only analyse new analysis periods
		SELECT NULL FROM Warehouse.Staging.FlashOfferReport_ReportData x
		WHERE 
			o.StartDate = x.StartDate
			AND o.EndDate = x.EndDate
			AND o.PeriodType = x.PeriodType
			AND o.PartnerID = x.RetailerID 
			AND o.IronOfferID = x.IronOfferID
			AND o.ControlGroupTypeID = x.ControlGroupTypeID
			AND o.CalculationDate = x.CalculationDate
		);

	/******************************************************************************
	Load ConsumerCombinations for the partner being reported on

	-- Create table for storing results:		

	CREATE TABLE Warehouse.Staging.FlashOfferReport_ConsumerCombinations (
		PartnerID int NOT NULL
		, ConsumerCombinationID int NOT NULL
		, CONSTRAINT PK_FlashOfferReport_ConsumerCombinations PRIMARY KEY CLUSTERED (ConsumerCombinationID)
	)
	******************************************************************************/
	
	--TRUNCATE TABLE Warehouse.Staging.FlashOfferReport_ConsumerCombinations; -- Table cleared in trigger stored procedure

	INSERT INTO Warehouse.Staging.FlashOfferReport_ConsumerCombinations (
		PartnerID
		, ConsumerCombinationID
	)

	SELECT DISTINCT
	   o.PartnerID
	   , cc.ConsumerCombinationID
    FROM Warehouse.Staging.FlashOfferReport_All_Offers o
	LEFT JOIN Warehouse.Relational.[Partner] p
		ON o.PartnerID = p.PartnerID
    INNER JOIN Warehouse.Relational.ConsumerCombination cc 
	   ON p.BrandID = cc.BrandID
	WHERE  
		p.PartnerName LIKE '%' + @RetailerNamePartialName + '%';

END