/******************************************************************************
Author: Jason Shipp
Created: 22/10/2018
Purpose: 
	- Load cardholder counts into Staging.WeeklySummaryV2_CardholderCounts table, at various groupings
------------------------------------------------------------------------------
Modification History

19/11/2018 Jason Shipp
	- Used WHERE EXISTS and a new index on the cardholder temp table to optimise query
	- Excluded AMEX

03/04/2019 Jason Shipp
    - Referenced PublisherID in nFI.Relational.AmexOffer instead of hardcoding -1

04/04/2019 Jason Shipp
	- Revised AMEX cardholder count logic to account for multiple PublisherIDs

08/07/2019 Jason Shipp
	- Added commented out logic to ensure cardholder dates overlap Iron Offer membership dates in the analysis periods
	- This lowers query performance, so there is no need to implement this unless this extra business logic is required

13/08/2019 Jason Shipp
	- Added delete of cases where the CardCustStartDate > CardCustEndDate in the #CardHolderStaging table, and added consolidation of overlapping date ranges

09/10/2019 Jason Shipp
	- Added AMEX-type publisher cardholders to calculation

07/01/2020 Jason Shipp
    - Amended Waitrose AMEX logic to fetch exposed members instead of members who clicked

******************************************************************************/
CREATE PROCEDURE [Staging].[Draft_WeeklySummaryV2_LoadCardholderCounts_RF]
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @Today DATE = CAST(GETDATE() AS DATE);

	/******************************************************************************
	Load partner alternates
	******************************************************************************/

	IF OBJECT_ID('tempdb..#PartnerAlternate') IS NOT NULL DROP TABLE #PartnerAlternate;
 
	SELECT 
		PartnerID
		, AlternatePartnerID
	INTO #PartnerAlternate
	FROM Warehouse.APW.PartnerAlternate

	UNION 

	SELECT 
		PartnerID
		, AlternatePartnerID
	FROM nFI.APW.PartnerAlternate;

	/******************************************************************************
	Load customer table, following logic in APW.DirectLoad_Staging_Customer_Fetch stored procedure
	******************************************************************************/

	IF OBJECT_ID ('tempdb..#Customer') IS NOT NULL DROP TABLE #Customer;

	CREATE TABLE #Customer (
		FanID int NOT NULL
		, CompositeID bigint NOT NULL
		, PublisherID int NOT NULL
		, ActivationDate date NOT NULL 
		, DeactivationDate date
	)

	-- Warehouse customers

	INSERT INTO #Customer (FanID, CompositeID, PublisherID, ActivationDate, DeactivationDate)	

	SELECT 
		f.ID AS FanID
		, f.CompositeID
		, 132 AS PublisherID
		, CAST(COALESCE(ca.ActivatedDate, pa.AgreedTCs,f.AgreedTCsDate) AS DATE) AS ActivationDate -- Date Activated
		, CASE
			WHEN f.[Status] = 0 OR f.AgreedTCs = 0 OR f.AgreedTCsDate IS NULL THEN COALESCE(ca.OptedOutDate,ca.DeactivatedDate)
			ELSE NULL
		END AS DeactivationDate
	FROM SLC_Report.dbo.Fan f
	LEFT JOIN 
			(SELECT FanID,[Date] AS AgreedTCs
			FROM Warehouse.Staging.InsightArchiveData AS iad
			WHERE iad.TypeID = 1
			) pa
		ON f.ID = pa.FanID
	LEFT JOIN Warehouse.MI.CustomerActiveStatus ca
		ON f.ID = ca.FanID
	LEFT JOIN Warehouse.Staging.Customer_TobeExcluded ctbe
		ON f.ID = ctbe.FanID
	WHERE 
		f.ClubID IN (132,138) 
		AND (f.AgreedTCs = 1 OR NOT(pa.AgreedTCs IS NULL))
		AND f.ID NOT IN (19587579)
		AND ctbe.FanID IS NULL;

	-- nFI customers

	INSERT INTO #Customer (FanID, CompositeID, PublisherID, ActivationDate, DeactivationDate)	

	SELECT 
		f.ID AS FanID
		, f.CompositeID
		, f.ClubID AS PublisherID
		, f.RegistrationDate AS ActivationDatek
		, NULL AS DeactivationDate
	FROM SLC_Report.dbo.Fan f
	INNER JOIN nFI.Relational.Club cl
		ON f.ClubID = cl.ClubID;

	CREATE CLUSTERED INDEX cx_Stuff ON #Customer (CompositeID);
	CREATE NONCLUSTERED INDEX ix_Stuff ON #Customer (ActivationDate ASC, DeactivationDate ASC) INCLUDE (FanID);	

	/******************************************************************************
	Load cardholder table
	- Temp table contains duplicate customers if customers activate/deactivate multiple cards, but these are handled when distinct FanIDs/CompositeIDs are loaded later
	******************************************************************************/

	IF OBJECT_ID ('tempdb..#CardHolderStaging') IS NOT NULL DROP TABLE #CardHolderStaging;

	SELECT DISTINCT
		c.FanID
		, c.CompositeID
		, c.PublisherID
		, CAST(CASE WHEN pc.AdditionDate > c.ActivationDate THEN pc.AdditionDate ELSE c.ActivationDate END AS date) AS CardCustStartDate
		, CAST(CASE WHEN (pc.RemovalDate < c.DeactivationDate OR c.DeactivationDate IS NULL) THEN pc.RemovalDate ELSE c.DeactivationDate END AS date) AS CardCustEndDate
	INTO #CardHolderStaging
	FROM #Customer c
	INNER JOIN SLC_Report.dbo.Pan pc
		ON c.CompositeID = pc.CompositeID;

	CREATE CLUSTERED INDEX cx_Stuff ON #CardHolderStaging (CompositeID, CardCustStartDate);

	DELETE from #CardHolderStaging
	WHERE CardCustStartDate > CardCustEndDate;

	-- Consolidate overlapping date ranges

	IF OBJECT_ID ('tempdb..#CardHolder') IS NOT NULL DROP TABLE #CardHolder;
	
	SELECT 
		PublisherID
		, FanID
		, CompositeID
		, CardCustStartDate = MIN(ts)
		, CardCustEndDate = MAX(ts)
	INTO #CardHolder
	FROM ( -- f
		SELECT 
			e.PublisherID
			, FanID
			, e.CompositeID
			, e.ts
			, RowPair = (1+ROW_NUMBER() OVER(PARTITION BY CompositeID ORDER BY rn))/2 
		FROM ( -- e
			SELECT 
				PublisherID
				, FanID
				, CompositeID
				, ts
				, [Type]
				, RangeEnd
				, rn,
				RangeStart = SUM(d.[Type]) OVER (PARTITION BY d.CompositeID ORDER BY rn ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
			FROM ( -- d
				SELECT 
					PublisherID
					, FanID
					, CompositeID
					, ts
					, [Type]
					, RangeEnd
					, rn = ROW_NUMBER() OVER (PARTITION BY CompositeID ORDER BY ts DESC, [type], RangeEnd DESC)
				FROM ( -- c
					SELECT 
						m.PublisherID
						, m.FanID
						, m.CompositeID
						, x.ts
						, x.[Type]
						, RangeEnd = SUM(x.[Type]) OVER (PARTITION BY m.CompositeID ORDER BY x.ts, x.[type] DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) 
					FROM #CardHolderStaging m
					CROSS APPLY (VALUES 
						(ISNULL(CardCustStartDate,'1900-01-01'), 1)
						, (ISNULL(CardCustEndDate,'2100-01-01'), -1)
					) x (ts, [Type])
				) c 
			) d
		) e 
		WHERE 
		e.RangeEnd = 0 OR e.RangeStart = 0
	) f
	GROUP BY 
	PublisherID
	, FanID
	, CompositeID
	, RowPair;

	CREATE NONCLUSTERED INDEX ix_Stuff ON #CardHolder (CompositeID) INCLUDE (CardCustStartDate, CardCustEndDate);
	CREATE NONCLUSTERED INDEX ix_Stuff2 ON #CardHolder (FanID) INCLUDE (CardCustStartDate, CardCustEndDate);
	CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_Stuff ON #CardHolder (CompositeID, FanID, CardCustStartDate, CardCustEndDate);

	/******************************************************************************
	Load calendar-IronOffer details table
	******************************************************************************/

	IF OBJECT_ID ('tempdb..#CalendarIOSetup') IS NOT NULL DROP TABLE #CalendarIOSetup;

	SELECT -- Warehouse
		cal.StartDate
		, cal.EndDate
		, cal.PeriodType
		, o.IronOfferID
		, s.OfferTypeForReports
		, COALESCE(pa.AlternatePartnerID, o.PartnerID) AS PartnerID
		, 'Warehouse' AS PublisherType
		, 132 AS PublisherID
	INTO #CalendarIOSetup
	FROM Warehouse.Staging.WeeklySummaryV2_RetailerAnalysisPeriods cal
	INNER JOIN 
			(SELECT 
			o.IronOfferID
			, COALESCE(pa.AlternatePartnerID, o.PartnerID) AS PartnerID
			, CAST(o.StartDate AS date) AS StartDate
			, CAST(o.EndDate AS date) AS EndDate
			, o.IsSignedOff
			, o.IronOfferName
			FROM Warehouse.Relational.IronOffer o
			LEFT JOIN #PartnerAlternate pa
			ON o.PartnerID = pa.PartnerID
			) o
		ON cal.RetailerID = o.PartnerID
		AND o.StartDate <= cal.EndDate
		AND (o.EndDate IS NULL OR o.EndDate >= cal.StartDate)
	LEFT JOIN Warehouse.Relational.IronOfferSegment s
		ON o.IronOfferID = s.IronOfferID
	LEFT JOIN #PartnerAlternate pa
		ON o.PartnerID = pa.PartnerID
	WHERE
		o.IssignedOff = 1
		AND o.IronOfferName NOT LIKE 'Spare%' -- Exclude spare offers

	UNION ALL

	SELECT -- nFI
		cal.StartDate
		, cal.EndDate
		, cal.PeriodType
		, o.ID AS IronOfferID
		, s.OfferTypeForReports
		, o.PartnerID
		, 'nFI' AS PublisherType
		, o.ClubID AS PublisherID
	FROM Warehouse.Staging.WeeklySummaryV2_RetailerAnalysisPeriods cal
	INNER JOIN
			(SELECT 
			o.ID
			, COALESCE(pa.AlternatePartnerID, o.PartnerID) AS PartnerID
			, o.ClubID
			, CAST(o.StartDate AS date) AS StartDate
			, CAST(o.EndDate AS date) AS EndDate
			, o.IsSignedOff
			, o.IronOfferName
			FROM nFI.Relational.IronOffer o
			LEFT JOIN #PartnerAlternate pa
			ON o.PartnerID = pa.PartnerID
			) o	
		ON cal.RetailerID = o.PartnerID
		AND o.StartDate <= cal.EndDate
		AND (o.EndDate IS NULL OR o.EndDate >= cal.StartDate)
	LEFT JOIN Warehouse.Relational.IronOfferSegment s
		ON o.ID = s.IronOfferID
	WHERE
		o.IssignedOff = 1
		AND o.IronOfferName NOT LIKE 'Spare%' -- Exclude spare offers

	UNION ALL

	SELECT -- AMEX
		cal.StartDate
		, cal.EndDate
		, cal.PeriodType
		, o.IronOfferID
		, s.OfferTypeForReports
		, o.PartnerID
		, 'AMEX' AS PublisherType
		, o.PublisherID
	FROM Warehouse.Staging.WeeklySummaryV2_RetailerAnalysisPeriods cal
	INNER JOIN
			(SELECT 
			o.IronOfferID
			, o.PublisherID
			, COALESCE(pa.AlternatePartnerID, o.RetailerID) AS PartnerID
			, o.StartDate
			, o.EndDate
			FROM nFI.Relational.AmexOffer o
			LEFT JOIN #PartnerAlternate pa
			ON o.RetailerID = pa.PartnerID
			) o	 
		ON cal.RetailerID = o.PartnerID
		AND o.StartDate <= cal.EndDate
		AND (o.EndDate IS NULL OR o.EndDate >= cal.StartDate)
	LEFT JOIN Warehouse.Relational.IronOfferSegment s
		ON o.IronOfferID = s.IronOfferID;

	CREATE CLUSTERED INDEX CIX_CalendarIOSetup ON #CalendarIOSetup (IronOfferID, StartDate, EndDate);

	/******************************************************************************
	Load distinct retailers to loop over
	******************************************************************************/

	IF OBJECT_ID ('tempdb..#Retailers') IS NOT NULL DROP TABLE #Retailers;

	SELECT 
		x.PartnerID
		, ROW_NUMBER() OVER (ORDER BY x.PartnerID) AS RowNum
	INTO #Retailers
	FROM (
		SELECT DISTINCT RetailerID AS PartnerID
		FROM Warehouse.Staging.WeeklySummaryV2_RetailerAnalysisPeriods
	) x;

	/******************************************************************************
	Declare iteration variables
	******************************************************************************/

	DECLARE @RowNum int;
	DECLARE @MaxRowNum int;
	DECLARE @PartnerID int;

	SET @RowNum = 1;
	SET @MaxRowNum = (SELECT MAX(RowNum) FROM #Retailers);

	/******************************************************************************
	Begin loop: iterate over retailers
	******************************************************************************/

	TRUNCATE TABLE [Staging].[WeeklySummaryV2_CardholderCounts_Interim]

	WHILE @RowNum <= @MaxRowNum

	BEGIN
		
		SET @PartnerID = (SELECT PartnerID FROM #Retailers WHERE RowNum = @RowNum)

		IF OBJECT_ID ('tempdb..#CalendarIO') IS NOT NULL DROP TABLE #CalendarIO;

		SELECT
			s.StartDate
			, s.EndDate
			, s.PeriodType
			, s.IronOfferID
			, s.OfferTypeForReports
			, s.PartnerID
			, s.PublisherType
			, s.PublisherID
		INTO #CalendarIO
		FROM #CalendarIOSetup s
		WHERE s.PartnerID = @PartnerID;

		CREATE CLUSTERED INDEX CIX_CalendarIO ON #CalendarIO (IronOfferID, StartDate, EndDate);
		CREATE NONCLUSTERED INDEX IX_CalendarIOPubID ON #CalendarIO (PublisherType, PublisherID) INCLUDE (IronOfferID);
		CREATE NONCLUSTERED INDEX IX_CalendarIOOfferType ON #CalendarIO (PublisherType, OfferTypeForReports) INCLUDE (IronOfferID);

		/******************************************************************************
		Load rows into cardholder counts table

		-- Create table for storing results

		CREATE TABLE Staging.WeeklySummaryV2_CardholderCounts (
			ID int NOT NULL IDENTITY(1, 1)
			, RetailerID int NOT NULL
			, PublisherID int
			, OfferTypeForReports varchar(100)
			, PeriodType varchar(50) NOT NULL
			, StartDate date NOT NULL
			, EndDate date NOT NULL
			, Cardholders int
			, [Grouping] varchar(50) NOT NULL
			, ReportDate date NOT NULL
		);

		ALTER TABLE Staging.WeeklySummaryV2_CardholderCounts ADD CONSTRAINT PK_WeeklySummaryV2_CardholderCounts PRIMARY KEY CLUSTERED (ID ASC);
		CREATE NONCLUSTERED INDEX IX_WeeklySummaryV2_CardholderCounts ON Staging.WeeklySummaryV2_CardholderCounts (RetailerID, StartDate, EndDate, ReportDate) INCLUDE (PublisherID, OfferTypeForReports);
		******************************************************************************/
	
		/*****************************
		Overall
		*****************************/
		
			/*****************************
			Warehouse
			*****************************/

				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim]
				SELECT -- Warehouse
						cal.PartnerID
					,	NULL AS PublisherID
					,	NULL AS OfferTypeForReports
					,	cal.PeriodType
					,	cal.StartDate
					,	cal.EndDate
					,	COUNT(DISTINCT(iom.CompositeID)) AS Cardholders
					,	'Retailer' AS [Grouping]
					,	@Today AS ReportDate
				FROM #CalendarIO cal
				INNER JOIN Warehouse.Relational.IronOfferMember iom
					ON cal.IronOfferID = iom.IronOfferID
				WHERE EXISTS (	SELECT NULL
								FROM #CardHolder ch
								WHERE iom.CompositeID = ch.CompositeID
								AND ch.CardCustStartDate <= cal.EndDate
								AND (ch.CardCustEndDate >= cal.StartDate OR ch.CardCustEndDate IS NULL)
							)
				AND (iom.StartDate <= cal.EndDate OR iom.StartDate IS NULL)
				AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
				AND cal.PublisherType = 'Warehouse'
				GROUP BY	cal.PartnerID
						,	cal.StartDate
						,	cal.EndDate
						,	cal.PeriodType
		
			/*****************************
			nFI
			*****************************/

				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim]
				SELECT -- nFI
						cal.PartnerID
					,	NULL AS PublisherID
					,	NULL AS OfferTypeForReports
					,	cal.PeriodType
					,	cal.StartDate
					,	cal.EndDate
					,	COUNT(DISTINCT(iom.FanID)) AS Cardholders
					,	'Retailer' AS [Grouping]
					,	@Today AS ReportDate
				FROM #CalendarIO cal
				INNER JOIN nFI.Relational.IronOfferMember iom
					ON cal.IronOfferID = iom.IronOfferID
				WHERE 
					EXISTS (
						SELECT NULL FROM #CardHolder ch
						WHERE 
						iom.FanID = ch.FanID
						AND ch.CardCustStartDate <= cal.EndDate
						AND (ch.CardCustEndDate >= cal.StartDate OR ch.CardCustEndDate IS NULL)
					)
				AND (iom.StartDate <= cal.EndDate OR iom.StartDate IS NULL)
				AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
				AND cal.PublisherType = 'nFI'
				GROUP BY	cal.PartnerID
						,	cal.StartDate
						,	cal.EndDate
						,	cal.PeriodType
		
			/*****************************
			Amex
			*****************************/

				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim]
				SELECT -- Max AMEX cardholders (=clicks) (Non-Universal or Universal)
					y.PartnerID
					, y.PublisherID
					, y.OfferTypeForReports
					, y.PeriodType
					, y.StartDate
					, y.EndDate			
					, MAX(y.Cardholders) AS Cardholders
					, y.[Grouping]
					, y.ReportDate
				FROM (
					SELECT -- AMEX Non-Universal
						c.PartnerID
						, NULL AS PublisherID
						, NULL AS OfferTypeForReports
						, c.PeriodType
						, c.StartDate
						, c.EndDate
						, SUM(c.ClickCounts) AS Cardholders
						, 'Retailer' AS [Grouping]
						, @Today AS ReportDate
					FROM (
						SELECT DISTINCT
							cal.PartnerID
							, cal.IronOfferID
							, cal.StartDate
							, cal.EndDate
							, cal.PeriodType
							, CASE WHEN (o.RetailerID = 4265 AND o.PublisherID = -1) THEN ame.ExposedCounts ELSE ame.ClickCounts END AS ClickCounts
							, ROW_NUMBER() OVER (PARTITION BY cal.IronOfferID, cal.StartDate, cal.EndDate, cal.PeriodType ORDER BY DATEDIFF(day, ame.ReceivedDate, cal.EndDate) ASC) AS DateRank
						FROM #CalendarIO cal
						INNER JOIN Warehouse.APW.AmexExposedClickCounts ame
							ON cal.IronOfferID = ame.IronOfferID
							--AND DATEADD(day, 1, ame.ReceivedDate) <= cal.EndDate
						INNER JOIN nFI.Relational.AmexOffer o
							ON cal.IronOfferID = o.IronOfferID
						WHERE 
							cal.PublisherType = 'AMEX'
							AND o.SegmentID <> 0
							AND o.SegmentID IS NOT NULL
							AND ame.ClickCounts >0
					) c
					WHERE c.DateRank = 1
					GROUP BY
						c.PartnerID
						, c.StartDate
						, c.EndDate
						, c.PeriodType
					UNION ALL
					SELECT -- AMEX Universal
						z.PartnerID
						, NULL AS PublisherID
						, NULL AS OfferTypeForReports
						, z.PeriodType
						, z.StartDate
						, z.EndDate
						, SUM(z.Cardholders) AS Cardholders -- Sum over publishers
						, 'Retailer' AS [Grouping]
						, @Today AS ReportDate
					FROM (
						SELECT -- AMEX Universal
							c.PublisherID
							, c.PartnerID
							, NULL AS OfferTypeForReports
							, c.PeriodType
							, c.StartDate
							, c.EndDate
							, MAX(c.ClickCounts) AS Cardholders -- Max per partner-publisher
							, 'Retailer' AS [Grouping]
						FROM (
							SELECT DISTINCT
								o.PublisherID
								, cal.PartnerID
								, cal.IronOfferID
								, cal.PeriodType
								, cal.StartDate
								, cal.EndDate
								, CASE WHEN (o.RetailerID = 4265 AND o.PublisherID = -1) THEN ame.ExposedCounts ELSE ame.ClickCounts END AS ClickCounts
								, ROW_NUMBER() OVER (PARTITION BY cal.IronOfferID, cal.StartDate, cal.EndDate, cal.PeriodType ORDER BY DATEDIFF(day, ame.ReceivedDate, cal.EndDate) ASC) AS DateRank
							FROM #CalendarIO cal
							INNER JOIN Warehouse.APW.AmexExposedClickCounts ame
								ON cal.IronOfferID = ame.IronOfferID
								--AND DATEADD(day, 1, ame.ReceivedDate) <= cal.EndDate
							INNER JOIN nFI.Relational.AmexOffer o
								ON cal.IronOfferID = o.IronOfferID
							WHERE 
								cal.PublisherType = 'AMEX'
								AND (o.SegmentID = 0 OR o.SegmentID IS NULL) -- Universal AMEX offers
								AND ame.ClickCounts >0
						) c
						WHERE c.DateRank = 1
						GROUP BY
							c.PublisherID
							, c.PartnerID
							, c.StartDate
							, c.EndDate
							, c.PeriodType
					) z
					GROUP BY
						z.PartnerID
						, z.PeriodType
						, z.StartDate
						, z.EndDate
				) y
				GROUP BY	y.PartnerID
						,	y.StartDate
						,	y.EndDate	
						,	y.PeriodType
						,	y.PublisherID
						,	y.OfferTypeForReports
						,	y.[Grouping]
						,	y.ReportDate

			/*****************************
			Insert to main table
			*****************************/

			INSERT INTO Staging.WeeklySummaryV2_CardholderCounts (
				RetailerID
				, PublisherID
				, OfferTypeForReports
				, PeriodType
				, StartDate
				, EndDate
				, Cardholders
				, [Grouping]
				, ReportDate
			)
			SELECT
				x.RetailerID
				, x.PublisherID
				, x.OfferTypeForReports
				, x.PeriodType
				, x.StartDate
				, x.EndDate		
				, SUM(x.Cardholders) AS Cardholders
				, x.[Grouping]
				, x.ReportDate
			FROM [Staging].[WeeklySummaryV2_CardholderCounts_Interim] x
			GROUP BY
				x.RetailerID
				, x.StartDate
				, x.EndDate	
				, x.PeriodType
				, x.PublisherID
				, x.OfferTypeForReports			
				, x.[Grouping]
				, x.ReportDate;

			TRUNCATE TABLE [Staging].[WeeklySummaryV2_CardholderCounts_Interim]

		/*****************************
		Grouped by publisher
		*****************************/
		
			/*****************************
			Warehouse
			*****************************/

			INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim]
			SELECT -- Warehouse
				cal.PartnerID
				, cal.PublisherID
				, NULL AS OfferTypeForReports
				, cal.PeriodType
				, cal.StartDate
				, cal.EndDate
				, COUNT(DISTINCT(iom.CompositeID)) AS Cardholders
				, 'RetailerPublisher' AS [Grouping]
				, @Today AS ReportDate
			FROM #CalendarIO cal
			INNER JOIN Warehouse.Relational.IronOfferMember iom
				ON cal.IronOfferID = iom.IronOfferID
			WHERE 
				EXISTS (
					SELECT NULL FROM #CardHolder ch
					WHERE 
					iom.CompositeID = ch.CompositeID
					AND ch.CardCustStartDate <= cal.EndDate
					AND (ch.CardCustEndDate >= cal.StartDate OR ch.CardCustEndDate IS NULL)
				)
				--AND EXISTS ( -- Check cardholder dates overlap Iron Offer membership dates
				--	SELECT NULL FROM #CardHolder ch
				--	WHERE
				--	(ch.CardCustStartDate <= CAST(iom.EndDate AS date) OR iom.EndDate IS NULL)
				--	AND (ch.CardCustEndDate >= CAST(iom.StartDate AS date) OR ch.CardCustEndDate IS NULL)
				--)
				AND (iom.StartDate <= cal.EndDate OR iom.StartDate IS NULL)
				AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
				AND cal.PublisherType = 'Warehouse'
			GROUP BY
				cal.PartnerID
				, cal.PublisherID
				, cal.StartDate
				, cal.EndDate
				, cal.PeriodType	
				
			/*****************************
			nFI
			*****************************/

			INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim]
			SELECT -- nFI
				cal.PartnerID
				, cal.PublisherID
				, NULL AS OfferTypeForReports
				, cal.PeriodType
				, cal.StartDate
				, cal.EndDate
				, COUNT(DISTINCT(iom.FanID)) AS Cardholders
				, 'RetailerPublisher' AS [Grouping]
				, @Today AS ReportDate
			FROM #CalendarIO cal
			INNER JOIN nFI.Relational.IronOfferMember iom
				ON cal.IronOfferID = iom.IronOfferID
			WHERE 
				EXISTS (
					SELECT NULL FROM #CardHolder ch
					WHERE iom.FanID = ch.FanID
					AND ch.CardCustStartDate <= cal.EndDate
					AND (ch.CardCustEndDate >= cal.StartDate OR ch.CardCustEndDate IS NULL)
				) 
				--AND EXISTS ( -- Check cardholder dates overlap Iron Offer membership dates
				--	SELECT NULL FROM #CardHolder ch
				--	WHERE
				--	(ch.CardCustStartDate <= CAST(iom.EndDate AS date) OR iom.EndDate IS NULL)
				--	AND (ch.CardCustEndDate >= CAST(iom.StartDate AS date) OR ch.CardCustEndDate IS NULL)
				--)
				AND (iom.StartDate <= cal.EndDate OR iom.StartDate IS NULL)
				AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
				AND cal.PublisherType = 'nFI'
			GROUP BY
				cal.PartnerID
				, cal.PublisherID
				, cal.StartDate
				, cal.EndDate
				, cal.PeriodType

			/*****************************
			Amex
			*****************************/

			INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim]
			SELECT -- Max AMEX cardholders (=clicks) (Non-Universal or Universal)
				y.PartnerID
				, y.PublisherID
				, y.OfferTypeForReports
				, y.PeriodType
				, y.StartDate
				, y.EndDate			
				, MAX(y.Cardholders) AS Cardholders
				, y.[Grouping]
				, y.ReportDate
			FROM (
				SELECT -- AMEX Non-Universal
					c.PartnerID
					, c.PublisherID
					, NULL AS OfferTypeForReports
					, c.PeriodType
					, c.StartDate
					, c.EndDate
					, SUM(c.ClickCounts) AS Cardholders
					, 'RetailerPublisher' AS [Grouping]
					, @Today AS ReportDate
				FROM (
					SELECT DISTINCT
						cal.PartnerID
						, cal.IronOfferID
						, o.PublisherID
						, cal.StartDate
						, cal.EndDate
						, cal.PeriodType
						, CASE WHEN (o.RetailerID = 4265 AND o.PublisherID = -1) THEN ame.ExposedCounts ELSE ame.ClickCounts END AS ClickCounts
						, ROW_NUMBER() OVER (PARTITION BY cal.IronOfferID, cal.StartDate, cal.EndDate, cal.PeriodType ORDER BY DATEDIFF(day, ame.ReceivedDate, cal.EndDate) ASC) AS DateRank
					FROM #CalendarIO cal
					INNER JOIN Warehouse.APW.AmexExposedClickCounts ame
						ON cal.IronOfferID = ame.IronOfferID
						--AND DATEADD(day, 1, ame.ReceivedDate) <= cal.EndDate
					INNER JOIN nFI.Relational.AmexOffer o
						ON cal.IronOfferID = o.IronOfferID
					WHERE 
						cal.PublisherType = 'AMEX'
						AND o.SegmentID <> 0
						AND o.SegmentID IS NOT NULL
						AND ame.ClickCounts >0
				) c
				WHERE c.DateRank = 1
				GROUP BY
					c.PartnerID
					, c.PublisherID
					, c.StartDate
					, c.EndDate
					, c.PeriodType
				UNION ALL
				SELECT -- AMEX Universal
					c.PartnerID
					, c.PublisherID
					, NULL AS OfferTypeForReports
					, c.PeriodType
					, c.StartDate
					, c.EndDate
					, MAX(c.ClickCounts) AS Cardholders -- Max per partner-publisher
					, 'RetailerPublisher' AS [Grouping]
					, @Today AS ReportDate
				FROM (
					SELECT DISTINCT
						cal.PartnerID
						, cal.IronOfferID
						, o.PublisherID
						, cal.PeriodType
						, cal.StartDate
						, cal.EndDate
						, CASE WHEN (o.RetailerID = 4265 AND o.PublisherID = -1) THEN ame.ExposedCounts ELSE ame.ClickCounts END AS ClickCounts
						, ROW_NUMBER() OVER (PARTITION BY cal.IronOfferID, cal.StartDate, cal.EndDate, cal.PeriodType ORDER BY DATEDIFF(day, ame.ReceivedDate, cal.EndDate) ASC) AS DateRank
					FROM #CalendarIO cal
					INNER JOIN Warehouse.APW.AmexExposedClickCounts ame
						ON cal.IronOfferID = ame.IronOfferID
						--AND DATEADD(day, 1, ame.ReceivedDate) <= cal.EndDate
					INNER JOIN nFI.Relational.AmexOffer o
						ON cal.IronOfferID = o.IronOfferID
					WHERE 
						cal.PublisherType = 'AMEX'
						AND (o.SegmentID = 0 OR o.SegmentID IS NULL) -- Universal AMEX offers
						AND ame.ClickCounts >0
				) c
				WHERE c.DateRank = 1
				GROUP BY
					c.PartnerID
					, c.PublisherID
					, c.StartDate
					, c.EndDate
					, c.PeriodType
			) y
			GROUP BY 
				y.PartnerID
				, y.StartDate
				, y.EndDate	
				, y.PeriodType
				, y.PublisherID
				, y.OfferTypeForReports
				, y.[Grouping]
				, y.ReportDate

			/*****************************
			Insert to main table
			*****************************/
		
			INSERT INTO Staging.WeeklySummaryV2_CardholderCounts (
				RetailerID
				, PublisherID
				, OfferTypeForReports
				, PeriodType
				, StartDate
				, EndDate
				, Cardholders
				, [Grouping]
				, ReportDate
			)
			SELECT
				x.RetailerID
				, x.PublisherID
				, x.OfferTypeForReports
				, x.PeriodType
				, x.StartDate
				, x.EndDate		
				, SUM(x.Cardholders) AS Cardholders
				, x.[Grouping]
				, x.ReportDate
			FROM [Staging].[WeeklySummaryV2_CardholderCounts_Interim] x
			GROUP BY
				x.RetailerID
				, x.StartDate
				, x.EndDate	
				, x.PeriodType
				, x.PublisherID
				, x.OfferTypeForReports			
				, x.[Grouping]
				, x.ReportDate;

			TRUNCATE TABLE [Staging].[WeeklySummaryV2_CardholderCounts_Interim]
			


		/*****************************
		Grouped by segment
		*****************************/
		
			/*****************************
			Warehouse
			*****************************/
			
			INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim]
			SELECT -- Warehouse
				cal.PartnerID
				, NULL AS PublisherID
				, cal.OfferTypeForReports
				, cal.PeriodType
				, cal.StartDate
				, cal.EndDate
				, COUNT(DISTINCT(iom.CompositeID)) AS Cardholders
				, 'RetailerOfferType' AS [Grouping]
				, @Today AS ReportDate
			FROM #CalendarIO cal
			INNER JOIN Warehouse.Relational.IronOfferMember iom
				ON cal.IronOfferID = iom.IronOfferID
			WHERE 
				EXISTS (
					SELECT NULL FROM #CardHolder ch
					WHERE
					iom.CompositeID = ch.CompositeID
					AND ch.CardCustStartDate <= cal.EndDate
					AND (ch.CardCustEndDate >= cal.StartDate OR ch.CardCustEndDate IS NULL)
				)
				--AND EXISTS ( -- Check cardholder dates overlap Iron Offer membership dates
				--	SELECT NULL FROM #CardHolder ch
				--	WHERE
				--	(ch.CardCustStartDate <= CAST(iom.EndDate AS date) OR iom.EndDate IS NULL)
				--	AND (ch.CardCustEndDate >= CAST(iom.StartDate AS date) OR ch.CardCustEndDate IS NULL)
				--)
				AND (iom.StartDate <= cal.EndDate OR iom.StartDate IS NULL)
				AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
				AND cal.PublisherType = 'Warehouse'
			GROUP BY
				cal.PartnerID
				, cal.StartDate
				, cal.EndDate
				, cal.PeriodType
				, cal.OfferTypeForReports
				
			/*****************************
			nFI
			*****************************/
			
			INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim]
			SELECT -- nFI
				cal.PartnerID
				, NULL AS PublisherID
				, cal.OfferTypeForReports
				, cal.PeriodType
				, cal.StartDate
				, cal.EndDate
				, COUNT(DISTINCT(iom.FanID)) AS Cardholders
				, 'RetailerOfferType' AS [Grouping]
				, @Today AS ReportDate
			FROM #CalendarIO cal
			INNER JOIN nFI.Relational.IronOfferMember iom
				ON cal.IronOfferID = iom.IronOfferID
			WHERE 
				EXISTS (
					SELECT NULL FROM #CardHolder ch
						WHERE iom.FanID = ch.FanID
						AND ch.CardCustStartDate <= cal.EndDate
						AND (ch.CardCustEndDate >= cal.StartDate OR ch.CardCustEndDate IS NULL)
				) 
				--AND EXISTS ( -- Check cardholder dates overlap Iron Offer membership dates
				--	SELECT NULL FROM #CardHolder ch
				--	WHERE
				--	(ch.CardCustStartDate <= CAST(iom.EndDate AS date) OR iom.EndDate IS NULL)
				--	AND (ch.CardCustEndDate >= CAST(iom.StartDate AS date) OR ch.CardCustEndDate IS NULL)
				--)
				AND (iom.StartDate <= cal.EndDate OR iom.StartDate IS NULL)
				AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
				AND cal.PublisherType = 'nFI'
			GROUP BY
				cal.PartnerID
				, cal.PublisherID
				, cal.StartDate
				, cal.EndDate
				, cal.PeriodType
				, cal.OfferTypeForReports

			/*****************************
			Amex
			*****************************/
			
			INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim]
			SELECT -- Max AMEX cardholders (=clicks) (Non-Universal or Universal)
				y.PartnerID
				, y.PublisherID
				, y.OfferTypeForReports
				, y.PeriodType
				, y.StartDate
				, y.EndDate			
				, MAX(y.Cardholders) AS Cardholders
				, y.[Grouping]
				, y.ReportDate
			FROM (
				SELECT -- AMEX Non-Universal
					c.PartnerID
					, NULL AS PublisherID
					, c.OfferTypeForReports
					, c.PeriodType
					, c.StartDate
					, c.EndDate
					, SUM(c.ClickCounts) AS Cardholders
					, 'RetailerOfferType' AS [Grouping]
					, @Today AS ReportDate
				FROM (
					SELECT DISTINCT
						cal.PartnerID
						, cal.IronOfferID
						, cal.OfferTypeForReports
						, cal.StartDate
						, cal.EndDate
						, cal.PeriodType
						, CASE WHEN (o.RetailerID = 4265 AND o.PublisherID = -1) THEN ame.ExposedCounts ELSE ame.ClickCounts END AS ClickCounts
						, ROW_NUMBER() OVER (PARTITION BY cal.IronOfferID, cal.StartDate, cal.EndDate, cal.PeriodType ORDER BY DATEDIFF(day, ame.ReceivedDate, cal.EndDate) ASC) AS DateRank
					FROM #CalendarIO cal
					INNER JOIN Warehouse.APW.AmexExposedClickCounts ame
						ON cal.IronOfferID = ame.IronOfferID
						--AND DATEADD(day, 1, ame.ReceivedDate) <= cal.EndDate
					INNER JOIN nFI.Relational.AmexOffer o
						ON cal.IronOfferID = o.IronOfferID
					WHERE 
						cal.PublisherType = 'AMEX'
						AND o.SegmentID <> 0
						AND o.SegmentID IS NOT NULL
						AND ame.ClickCounts >0
				) c
				WHERE c.DateRank = 1
				GROUP BY
					c.PartnerID
					, c.StartDate
					, c.EndDate
					, c.PeriodType
					, c.OfferTypeForReports
				UNION ALL
				SELECT -- AMEX Universal
					z.PartnerID
					, NULL AS PublisherID
					, z.OfferTypeForReports
					, z.PeriodType
					, z.StartDate
					, z.EndDate
					, SUM(z.Cardholders) AS Cardholders -- Sum over publishers
					, 'RetailerOfferType' AS [Grouping]
					, @Today AS ReportDate
				FROM (
					SELECT -- AMEX Universal
						c.PublisherID
						, c.PartnerID
						, c.OfferTypeForReports
						, c.PeriodType
						, c.StartDate
						, c.EndDate
						, MAX(c.ClickCounts) AS Cardholders -- Max per partner-publisher
						, 'RetailerOfferType' AS [Grouping]
					FROM (
						SELECT DISTINCT
							o.PublisherID
							, cal.PartnerID
							, cal.IronOfferID
							, cal.OfferTypeForReports
							, cal.PeriodType
							, cal.StartDate
							, cal.EndDate
							, CASE WHEN (o.RetailerID = 4265 AND o.PublisherID = -1) THEN ame.ExposedCounts ELSE ame.ClickCounts END AS ClickCounts
							, ROW_NUMBER() OVER (PARTITION BY cal.IronOfferID, cal.StartDate, cal.EndDate, cal.PeriodType ORDER BY DATEDIFF(day, ame.ReceivedDate, cal.EndDate) ASC) AS DateRank
						FROM #CalendarIO cal
						INNER JOIN Warehouse.APW.AmexExposedClickCounts ame
							ON cal.IronOfferID = ame.IronOfferID
							--AND DATEADD(day, 1, ame.ReceivedDate) <= cal.EndDate
						INNER JOIN nFI.Relational.AmexOffer o
							ON cal.IronOfferID = o.IronOfferID
						WHERE 
							cal.PublisherType = 'AMEX'
							AND (o.SegmentID = 0 OR o.SegmentID IS NULL) -- Universal AMEX offers
							AND ame.ClickCounts >0
					) c
					WHERE c.DateRank = 1
					GROUP BY
						c.PublisherID
						, c.PartnerID
						, c.StartDate
						, c.EndDate
						, c.PeriodType
						, c.OfferTypeForReports
				) z
				GROUP BY
					z.PartnerID
					, z.OfferTypeForReports
					, z.PeriodType
					, z.StartDate
					, z.EndDate
			) y
			GROUP BY 
				y.PartnerID
				, y.StartDate
				, y.EndDate	
				, y.PeriodType
				, y.PublisherID
				, y.OfferTypeForReports
				, y.[Grouping]
				, y.ReportDate

			/*****************************
			Insert to main table
			*****************************/
	
			INSERT INTO Staging.WeeklySummaryV2_CardholderCounts (
				RetailerID
				, PublisherID
				, OfferTypeForReports
				, PeriodType
				, StartDate
				, EndDate
				, Cardholders
				, [Grouping]
				, ReportDate
			)
			SELECT
				x.RetailerID
				, x.PublisherID
				, x.OfferTypeForReports
				, x.PeriodType
				, x.StartDate
				, x.EndDate		
				, SUM(x.Cardholders) AS Cardholders
				, x.[Grouping]
				, x.ReportDate
			FROM [Staging].[WeeklySummaryV2_CardholderCounts_Interim] x
			GROUP BY
				x.RetailerID
				, x.StartDate
				, x.EndDate	
				, x.PeriodType
				, x.PublisherID
				, x.OfferTypeForReports			
				, x.[Grouping]
				, x.ReportDate

			OPTION(RECOMPILE);
			
			TRUNCATE TABLE [Staging].[WeeklySummaryV2_CardholderCounts_Interim];


		SET @RowNum = @RowNum + 1;

	END -- End loop over retailers

END