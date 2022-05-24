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
CREATE PROCEDURE [Staging].[Draft_WeeklySummaryV2_LoadCardholderCounts_New]
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @Today DATE = CAST(GETDATE() AS DATE);

	/******************************************************************************
	Load partner alternates
	******************************************************************************/

		IF OBJECT_ID('tempdb..#PartnerAlternate') IS NOT NULL DROP TABLE #PartnerAlternate;
		SELECT	PartnerID
			,	AlternatePartnerID
		INTO #PartnerAlternate
		FROM [Warehouse].[APW].[PartnerAlternate]
		UNION
		SELECT	PartnerID
			,	AlternatePartnerID
		FROM [nFI].[APW].[PartnerAlternate];

	/******************************************************************************
	Load customer table, following logic in APW.DirectLoad_Staging_Customer_Fetch stored procedure
	******************************************************************************/

		IF OBJECT_ID ('tempdb..#Customer') IS NOT NULL DROP TABLE #Customer;

		CREATE TABLE #Customer (FanID INT NOT NULL
							,	CompositeID BIGINT NOT NULL
							,	PublisherID INT NOT NULL
							,	ActivationDate DATE NOT NULL 
							,	DeactivationDate DATE)

		-- Warehouse customers

			INSERT INTO #Customer (FanID, CompositeID, PublisherID, ActivationDate, DeactivationDate)	
			SELECT	f.ID AS FanID
				,	f.CompositeID
				,	132 AS PublisherID
				,	CAST(COALESCE(ca.ActivatedDate, pa.AgreedTCs,f.AgreedTCsDate) AS DATE) AS ActivationDate -- Date Activated
				,	CASE
						WHEN f.[Status] = 0 OR f.AgreedTCs = 0 OR f.AgreedTCsDate IS NULL THEN COALESCE(ca.OptedOutDate,ca.DeactivatedDate)
						ELSE NULL
					END AS DeactivationDate
			FROM [SLC_Report].[dbo].[Fan] f
			LEFT JOIN (	SELECT FanID,[Date] AS AgreedTCs
						FROM [Warehouse].[Staging].[InsightArchiveData] AS iad
						WHERE iad.TypeID = 1) pa
				ON f.ID = pa.FanID
			LEFT JOIN [Warehouse].[MI].[CustomerActiveStatus] ca
				ON f.ID = ca.FanID
			WHERE f.ClubID IN (132,138) 
			AND (f.AgreedTCs = 1 OR NOT(pa.AgreedTCs IS NULL))
			AND NOT EXISTS (	SELECT 1
								FROM [Warehouse].[Staging].[Customer_TobeExcluded] ctbe
								WHERE f.ID = ctbe.FanID)
			AND f.ID NOT IN (19587579);

		-- nFI customers

			INSERT INTO #Customer (FanID, CompositeID, PublisherID, ActivationDate, DeactivationDate)	

			SELECT	f.ID AS FanID
				,	f.CompositeID
				,	f.ClubID AS PublisherID
				,	f.RegistrationDate AS ActivationDate
				,	NULL AS DeactivationDate
			FROM [SLC_Report].[dbo].[Fan] f
			INNER JOIN [nFI].[Relational].[Club] cl
				ON f.ClubID = cl.ClubID;

		-- Virgin customers

			INSERT INTO #Customer (FanID, CompositeID, PublisherID, ActivationDate, DeactivationDate)	

			SELECT	f.ID AS FanID
				,	f.CompositeID
				,	f.ClubID AS PublisherID
				,	f.RegistrationDate AS ActivationDate
				,	DeactivatedDate AS DeactivationDate
			FROM [SLC_Report].[dbo].[Fan] f
			LEFT JOIN [WH_Virgin].[Derived].[Customer] cu
				ON f.ID = cu.FanID
			WHERE f.ClubID IN (166) ;

		CREATE CLUSTERED INDEX cx_Stuff ON #Customer (CompositeID);
		CREATE NONCLUSTERED INDEX ix_Stuff ON #Customer (ActivationDate ASC, DeactivationDate ASC) INCLUDE (FanID);	

	/******************************************************************************
	Load cardholder table
	- Temp table contains duplicate customers if customers activate/deactivate multiple cards, but these are handled when distinct FanIDs/CompositeIDs are loaded later
	******************************************************************************/

		IF OBJECT_ID ('tempdb..#CardHolderStaging') IS NOT NULL DROP TABLE #CardHolderStaging;

		SELECT	DISTINCT
				c.FanID
			,	c.CompositeID
			,	c.PublisherID
			,	CONVERT(DATE,	CASE
									WHEN pc.AdditionDate > c.ActivationDate THEN pc.AdditionDate
									ELSE c.ActivationDate 
								END) AS CardCustStartDate
			,	CONVERT(DATE,	CASE
									WHEN (pc.RemovalDate < c.DeactivationDate OR c.DeactivationDate IS NULL) THEN pc.RemovalDate
									ELSE c.DeactivationDate 
								END) AS CardCustEndDate
		INTO #CardHolderStaging
		FROM #Customer c
		INNER JOIN [SLC_Report].[dbo].[Pan] pc
			ON c.CompositeID = pc.CompositeID;

		INSERT INTO #CardHolderStaging
		SELECT	DISTINCT
				c.FanID
			,	c.CompositeID
			,	c.PublisherID
			,	c.ActivationDate
			,	c.DeactivationDate
		FROM #Customer c
		WHERE c.PublisherID = 166;

		CREATE CLUSTERED INDEX cx_Stuff ON #CardHolderStaging (CompositeID, CardCustStartDate);

		DELETE
		FROM #CardHolderStaging
		WHERE CardCustStartDate > CardCustEndDate;

		-- Consolidate overlapping date ranges

			IF OBJECT_ID ('tempdb..#CardHolder') IS NOT NULL DROP TABLE #CardHolder;
	
			SELECT	PublisherID
				,	FanID
				,	CompositeID
				,	CardCustStartDate = MIN(ts)
				,	CardCustEndDate = MAX(ts)
			INTO #CardHolder
			FROM (	SELECT	e.PublisherID	-- f
						,	FanID
						,	e.CompositeID
						,	e.ts
						,	RowPair = (1 + ROW_NUMBER() OVER(PARTITION BY CompositeID ORDER BY rn))/2 
					FROM (	SELECT	PublisherID	 -- e
								,	FanID
								,	CompositeID
								,	ts
								,	[Type]
								,	RangeEnd
								,	rn
								,	RangeStart = SUM(d.[Type]) OVER (PARTITION BY d.CompositeID ORDER BY rn ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
							FROM (	SELECT	PublisherID	-- d
										,	FanID
										,	CompositeID
										,	ts
										,	[Type]
										,	RangeEnd
										,	rn = ROW_NUMBER() OVER (PARTITION BY CompositeID ORDER BY ts DESC, [type], RangeEnd DESC)
									FROM (	SELECT	m.PublisherID	-- c
												,	m.FanID
												,	m.CompositeID
												,	x.ts
												,	x.[Type]
												,	RangeEnd = SUM(x.[Type]) OVER (PARTITION BY m.CompositeID ORDER BY x.ts, x.[type] DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
											FROM #CardHolderStaging m
											CROSS APPLY (VALUES	(ISNULL(CardCustStartDate,'1900-01-01'), 1)
															,	(ISNULL(CardCustEndDate,'2100-01-01'), -1)) x (ts, [Type])) c 
									) d
							) e 
					WHERE e.RangeEnd = 0
					OR e.RangeStart = 0) f
			GROUP BY	PublisherID
					,	FanID
					,	CompositeID
					,	RowPair;

			CREATE NONCLUSTERED INDEX ix_Stuff ON #CardHolder (CompositeID) INCLUDE (CardCustStartDate, CardCustEndDate);
			CREATE NONCLUSTERED INDEX ix_Stuff2 ON #CardHolder (FanID) INCLUDE (CardCustStartDate, CardCustEndDate);
			CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_Stuff ON #CardHolder (CompositeID, CardCustStartDate, CardCustEndDate);

	/******************************************************************************
	Load calendar-IronOffer details table
	******************************************************************************/

		IF OBJECT_ID ('tempdb..#CalendarIOSetup') IS NOT NULL DROP TABLE #CalendarIOSetup;

		SELECT	cal.StartDate	-- Warehouse
			,	cal.EndDate
			,	cal.PeriodType
			,	o.IronOfferID
			,	s.OfferTypeForReports
			,	COALESCE(pa.AlternatePartnerID, o.PartnerID) AS PartnerID
			,	'Warehouse' AS PublisherType
			,	132 AS PublisherID
		INTO #CalendarIOSetup
		FROM [Warehouse].[Staging].[WeeklySummaryV2_RetailerAnalysisPeriods] cal
		INNER JOIN (SELECT	o.IronOfferID
						,	COALESCE(pa.AlternatePartnerID, o.PartnerID) AS PartnerID
						,	CAST(o.StartDate AS date) AS StartDate
						,	CAST(o.EndDate AS date) AS EndDate
						,	o.IsSignedOff
						,	o.IronOfferName
					FROM [Warehouse].[Relational].[IronOffer] o
					LEFT JOIN #PartnerAlternate pa
						ON o.PartnerID = pa.PartnerID) o
			ON cal.RetailerID = o.PartnerID
			AND o.StartDate <= cal.EndDate
			AND (o.EndDate IS NULL OR o.EndDate >= cal.StartDate)
		LEFT JOIN [Warehouse].[Relational].[IronOfferSegment] s
			ON o.IronOfferID = s.IronOfferID
		LEFT JOIN #PartnerAlternate pa
			ON o.PartnerID = pa.PartnerID
		WHERE o.IssignedOff = 1
		AND o.IronOfferName NOT LIKE 'Spare%' -- Exclude spare offers

		UNION ALL

		SELECT	cal.StartDate	-- nFI
			,	cal.EndDate
			,	cal.PeriodType
			,	o.ID AS IronOfferID
			,	s.OfferTypeForReports
			,	o.PartnerID
			,	'nFI' AS PublisherType
			,	o.ClubID AS PublisherID
		FROM [Warehouse].[Staging].[WeeklySummaryV2_RetailerAnalysisPeriods] cal
		INNER JOIN (SELECT o.ID
						,	COALESCE(pa.AlternatePartnerID, o.PartnerID) AS PartnerID
						,	o.ClubID
						,	CAST(o.StartDate AS date) AS StartDate
						,	CAST(o.EndDate AS date) AS EndDate
						,	o.IsSignedOff
						,	o.IronOfferName
					FROM [nFI].[Relational].[IronOffer] o
					LEFT JOIN #PartnerAlternate pa
						ON o.PartnerID = pa.PartnerID) o	
			ON cal.RetailerID = o.PartnerID
			AND o.StartDate <= cal.EndDate
			AND (o.EndDate IS NULL OR o.EndDate >= cal.StartDate)
		LEFT JOIN [Warehouse].[Relational].[IronOfferSegment] s
			ON o.ID = s.IronOfferID
		WHERE o.IssignedOff = 1
		AND o.IronOfferName NOT LIKE 'Spare%' -- Exclude spare offers

		UNION ALL

		SELECT	cal.StartDate	-- Virgin
			,	cal.EndDate
			,	cal.PeriodType
			,	o.IronOfferID
			,	s.OfferTypeForReports
			,	o.PartnerID
			,	'Virgin' AS PublisherType
			,	o.ClubID AS PublisherID
		FROM [Warehouse].[Staging].[WeeklySummaryV2_RetailerAnalysisPeriods] cal
		INNER JOIN (SELECT	o.IronOfferID
						,	COALESCE(pa.AlternatePartnerID, o.PartnerID) AS PartnerID
						,	o.ClubID
						,	CAST(o.StartDate AS date) AS StartDate
						,	CAST(o.EndDate AS date) AS EndDate
						,	o.IsSignedOff
						,	o.IronOfferName
						,	o.SegmentName AS OfferTypeForReports
					FROM [WH_Virgin].[Derived].[IronOffer] o
					LEFT JOIN #PartnerAlternate pa
						ON o.PartnerID = pa.PartnerID) o	
			ON cal.RetailerID = o.PartnerID
			AND o.StartDate <= cal.EndDate
			AND (o.EndDate IS NULL OR o.EndDate >= cal.StartDate)
		LEFT JOIN [Warehouse].[Relational].[IronOfferSegment] s
			ON o.IronOfferID = s.IronOfferID
		WHERE o.IssignedOff = 1
		AND o.IronOfferName NOT LIKE 'Spare%' -- Exclude spare offers

		UNION ALL

		SELECT	cal.StartDate	-- AMEX
			,	cal.EndDate
			,	cal.PeriodType
			,	o.IronOfferID
			,	s.OfferTypeForReports
			,	o.PartnerID
			,	'AMEX' AS PublisherType
			,	o.PublisherID
		FROM [Warehouse].[Staging].[WeeklySummaryV2_RetailerAnalysisPeriods] cal
		INNER JOIN (SELECT	o.IronOfferID
						,	o.PublisherID
						,	COALESCE(pa.AlternatePartnerID, o.RetailerID) AS PartnerID
						,	o.StartDate
						,	o.EndDate
					FROM [nFI].[Relational].[AmexOffer] o
					LEFT JOIN #PartnerAlternate pa
						ON o.RetailerID = pa.PartnerID) o	 
			ON cal.RetailerID = o.PartnerID
			AND o.StartDate <= cal.EndDate
			AND (o.EndDate IS NULL OR o.EndDate >= cal.StartDate)
		LEFT JOIN [Warehouse].[Relational].[IronOfferSegment] s
			ON o.IronOfferID = s.IronOfferID;

		CREATE CLUSTERED INDEX CIX_CalendarIOSetup ON #CalendarIOSetup (IronOfferID, StartDate, EndDate);

	/******************************************************************************
	Load distinct retailers to loop over
	******************************************************************************/

		IF OBJECT_ID ('tempdb..#Retailers') IS NOT NULL DROP TABLE #Retailers;

		SELECT	x.PartnerID
			,	ROW_NUMBER() OVER (ORDER BY x.PartnerID) AS RowNum
		INTO #Retailers
		FROM (	SELECT	DISTINCT RetailerID AS PartnerID
				FROM [Warehouse].Staging.WeeklySummaryV2_RetailerAnalysisPeriods) x;

		IF OBJECT_ID ('tempdb..#IronOfferMember') IS NOT NULL DROP TABLE #IronOfferMember;
		CREATE TABLE #IronOfferMember (	ID INT IDENTITY PRIMARY KEY
									,	PartnerID INT
									,	PublisherID INT
									,	OfferTypeForReports VARCHAR(25)
									,	PeriodType VARCHAR(25)
									,	StartDate DATE
									,	EndDate DATE
									,	CompositeID BIGINT
									,	FanID BIGINT)
									
		CREATE NONCLUSTERED COLUMNSTORE INDEX CSX_All ON #IronOfferMember (PartnerID, PublisherID, OfferTypeForReports, PeriodType, StartDate, CompositeID, FanID)

	/******************************************************************************
	Declare iteration variables
	******************************************************************************/

		DECLARE @RowNum int;
		DECLARE @MaxRowNum int;
		DECLARE @PartnerID int;

		DECLARE @MinStartDate DATE
			,	@Query_IronOfferMember VARCHAR(MAX)

		SET @RowNum = 1;
		SET @MaxRowNum = (SELECT MAX(RowNum) FROM #Retailers);

	/******************************************************************************
	Begin loop: iterate over retailers
	******************************************************************************/

		WHILE @RowNum <= @MaxRowNum

		BEGIN
			/*****************************
			Prepare calendar table for individual partner
			*****************************/
		
				SET @PartnerID = (SELECT PartnerID FROM #Retailers WHERE RowNum = @RowNum)

				IF OBJECT_ID ('tempdb..#CalendarIO') IS NOT NULL DROP TABLE #CalendarIO;
				SELECT	s.StartDate
					,	s.EndDate
					,	s.PeriodType
					,	s.IronOfferID
					,	s.OfferTypeForReports
					,	s.PartnerID
					,	s.PublisherType
					,	s.PublisherID
				INTO #CalendarIO
				FROM #CalendarIOSetup s
				WHERE s.PartnerID = @PartnerID;

				CREATE CLUSTERED INDEX CIX_CalendarIO ON #CalendarIO (IronOfferID, StartDate, EndDate);
				CREATE NONCLUSTERED INDEX IX_CalendarIO ON #CalendarIO (PublisherType, PublisherID, OfferTypeForReports);

			/*****************************
			Prepare IronOfferMember table for individual partner
			*****************************/

				SELECT @MinStartDate =	MIN(StartDate)
				FROM #CalendarIO

				DROP INDEX CSX_All ON #IronOfferMember

				SET @Query_IronOfferMember = '
				TRUNCATE TABLE #IronOfferMember

				INSERT INTO #IronOfferMember
				SELECT	cal.PartnerID	--	Warehouse
					,	cal.PublisherID
					,	cal.OfferTypeForReports
					,	cal.PeriodType
					,	cal.StartDate
					,	cal.EndDate
					,	CompositeID = iom.CompositeID
					,	FanID = NULL
				FROM #CalendarIO cal
				INNER JOIN [Warehouse].[Relational].[IronOfferMember] iom
					ON cal.IronOfferID = iom.IronOfferID
				WHERE EXISTS (	SELECT NULL
								FROM #CardHolder ch
								WHERE iom.CompositeID = ch.CompositeID
								AND ch.CardCustStartDate <= cal.EndDate
								AND (ch.CardCustEndDate >= cal.StartDate OR ch.CardCustEndDate IS NULL))
				AND ''' + CONVERT(VARCHAR(10), @MinStartDate) + ''' <= iom.StartDate
				AND (iom.StartDate <= cal.EndDate)
				AND (iom.EndDate >= cal.StartDate)
				AND cal.PublisherType = ''Warehouse''

				INSERT INTO #IronOfferMember
				SELECT	cal.PartnerID	--	Warehouse
					,	cal.PublisherID
					,	cal.OfferTypeForReports
					,	cal.PeriodType
					,	cal.StartDate
					,	cal.EndDate
					,	CompositeID = iom.CompositeID
					,	FanID = NULL
				FROM #CalendarIO cal
				INNER JOIN [Warehouse].[Relational].[IronOfferMember] iom
					ON cal.IronOfferID = iom.IronOfferID
				WHERE EXISTS (	SELECT NULL
								FROM #CardHolder ch
								WHERE iom.CompositeID = ch.CompositeID
								AND ch.CardCustStartDate <= cal.EndDate
								AND (ch.CardCustEndDate >= cal.StartDate OR ch.CardCustEndDate IS NULL))
				AND ''' + CONVERT(VARCHAR(10), @MinStartDate) + ''' <= iom.StartDate
				AND (iom.StartDate <= cal.EndDate)
				AND (iom.EndDate IS NULL)
				AND cal.PublisherType = ''Warehouse''
				
				INSERT INTO #IronOfferMember
				SELECT	cal.PartnerID	--	Virgin
					,	cal.PublisherID
					,	cal.OfferTypeForReports
					,	cal.PeriodType
					,	cal.StartDate
					,	cal.EndDate
					,	CompositeID = iom.CompositeID
					,	FanID = NULL
				FROM #CalendarIO cal
				INNER JOIN [WH_Virgin].[Derived].[IronOfferMember] iom
					ON cal.IronOfferID = iom.IronOfferID
				WHERE EXISTS (	SELECT NULL
								FROM #CardHolder ch
								WHERE iom.CompositeID = ch.CompositeID
								AND ch.CardCustStartDate <= cal.EndDate
								AND (ch.CardCustEndDate >= cal.StartDate OR ch.CardCustEndDate IS NULL))
				AND ''' + CONVERT(VARCHAR(10), @MinStartDate) + ''' <= iom.StartDate
				AND (iom.StartDate <= cal.EndDate)
				AND (iom.EndDate >= cal.StartDate)
				AND cal.PublisherType = ''Virgin''

				INSERT INTO #IronOfferMember
				SELECT	cal.PartnerID	--	Virgin
					,	cal.PublisherID
					,	cal.OfferTypeForReports
					,	cal.PeriodType
					,	cal.StartDate
					,	cal.EndDate
					,	CompositeID = iom.CompositeID
					,	FanID = NULL
				FROM #CalendarIO cal
				INNER JOIN [WH_Virgin].[Derived].[IronOfferMember] iom
					ON cal.IronOfferID = iom.IronOfferID
				WHERE EXISTS (	SELECT NULL
								FROM #CardHolder ch
								WHERE iom.CompositeID = ch.CompositeID
								AND ch.CardCustStartDate <= cal.EndDate
								AND (ch.CardCustEndDate >= cal.StartDate OR ch.CardCustEndDate IS NULL))
				AND ''' + CONVERT(VARCHAR(10), @MinStartDate) + ''' <= iom.StartDate
				AND (iom.StartDate <= cal.EndDate)
				AND (iom.EndDate IS NULL)
				AND cal.PublisherType = ''Virgin''

				INSERT INTO #IronOfferMember
				SELECT	cal.PartnerID	--	nFI
					,	cal.PublisherID
					,	cal.OfferTypeForReports
					,	cal.PeriodType
					,	cal.StartDate
					,	cal.EndDate
					,	CompositeID = NULL
					,	FanID = iom.FanID
				FROM #CalendarIO cal
				INNER JOIN [nFI].[Relational].[IronOfferMember] iom
					ON cal.IronOfferID = iom.IronOfferID
				WHERE EXISTS (	SELECT NULL
								FROM #CardHolder ch
								WHERE iom.FanID = ch.FanID
								AND ch.CardCustStartDate <= cal.EndDate
								AND (ch.CardCustEndDate >= cal.StartDate OR ch.CardCustEndDate IS NULL))
				AND ''' + CONVERT(VARCHAR(10), @MinStartDate) + ''' <= iom.StartDate
				AND (iom.StartDate <= cal.EndDate)
				AND (iom.EndDate >= cal.StartDate)
				AND cal.PublisherType = ''nFI''

				INSERT INTO #IronOfferMember
				SELECT	cal.PartnerID	--	nFI
					,	cal.PublisherID
					,	cal.OfferTypeForReports
					,	cal.PeriodType
					,	cal.StartDate
					,	cal.EndDate
					,	CompositeID = NULL
					,	FanID = iom.FanID
				FROM #CalendarIO cal
				INNER JOIN [nFI].[Relational].[IronOfferMember] iom
					ON cal.IronOfferID = iom.IronOfferID
				WHERE EXISTS (	SELECT NULL
								FROM #CardHolder ch
								WHERE iom.FanID = ch.FanID
								AND ch.CardCustStartDate <= cal.EndDate
								AND (ch.CardCustEndDate >= cal.StartDate OR ch.CardCustEndDate IS NULL))
				AND ''' + CONVERT(VARCHAR(10), @MinStartDate) + ''' <= iom.StartDate
				AND (iom.StartDate <= cal.EndDate)
				AND (iom.EndDate IS NULL)
				AND cal.PublisherType = ''nFI'''

				EXEC (@Query_IronOfferMember)
				
				CREATE NONCLUSTERED COLUMNSTORE INDEX CSX_All ON #IronOfferMember (PartnerID, PublisherID, OfferTypeForReports, PeriodType, StartDate, CompositeID, FanID)

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

				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts] (	RetailerID
																		,	PublisherID
																		,	OfferTypeForReports
																		,	PeriodType
																		,	StartDate
																		,	EndDate
																		,	Cardholders
																		,	[Grouping]
																		,	ReportDate)
				SELECT	x.PartnerID
					,	x.PublisherID
					,	x.OfferTypeForReports
					,	x.PeriodType
					,	x.StartDate
					,	x.EndDate		
					,	SUM(x.Cardholders) AS Cardholders
					,	x.[Grouping]
					,	x.ReportDate
				FROM (	SELECT	iom.PartnerID -- Warehouse / Virgin
							,	NULL AS PublisherID
							,	NULL AS OfferTypeForReports
							,	iom.PeriodType
							,	iom.StartDate
							,	iom.EndDate
							,	COUNT(DISTINCT(iom.CompositeID)) AS Cardholders
							,	'Retailer' AS [Grouping]
							,	@Today AS ReportDate
						FROM #IronOfferMember iom
						GROUP BY	iom.PartnerID
								,	iom.StartDate
								,	iom.EndDate
								,	iom.PeriodType

						UNION ALL

						SELECT	iom.PartnerID -- nFI
							,	NULL AS PublisherID
							,	NULL AS OfferTypeForReports
							,	iom.PeriodType
							,	iom.StartDate
							,	iom.EndDate
							,	COUNT(DISTINCT(iom.FanID)) AS Cardholders
							,	'Retailer' AS [Grouping]
							,	@Today AS ReportDate
						FROM #IronOfferMember iom
						GROUP BY	iom.PartnerID
								,	iom.StartDate
								,	iom.EndDate
								,	iom.PeriodType

						UNION ALL

						SELECT	y.PartnerID	-- Max AMEX cardholders (=clicks) (Non-Universal or Universal)
							,	y.PublisherID
							,	y.OfferTypeForReports
							,	y.PeriodType
							,	y.StartDate
							,	y.EndDate			
							,	MAX(y.Cardholders) AS Cardholders
							,	y.[Grouping]
							,	y.ReportDate
						FROM (	SELECT	c.PartnerID	-- AMEX Non-Universal
									,	NULL AS PublisherID
									,	NULL AS OfferTypeForReports
									,	c.PeriodType
									,	c.StartDate
									,	c.EndDate
									,	SUM(c.ClickCounts) AS Cardholders
									,	'Retailer' AS [Grouping]
									,	@Today AS ReportDate
								FROM (	SELECT	DISTINCT
												cal.PartnerID
											,	cal.IronOfferID
											,	cal.StartDate
											,	cal.EndDate
											,	cal.PeriodType
											,	CASE WHEN (o.RetailerID = 4265 AND o.PublisherID = -1) THEN ame.ExposedCounts ELSE ame.ClickCounts END AS ClickCounts
											,	ROW_NUMBER() OVER (PARTITION BY cal.IronOfferID, cal.StartDate, cal.EndDate, cal.PeriodType ORDER BY DATEDIFF(day, ame.ReceivedDate, cal.EndDate) ASC) AS DateRank
										FROM #CalendarIO cal
										INNER JOIN [Warehouse].[APW].[AmexExposedClickCounts] ame
											ON cal.IronOfferID = ame.IronOfferID
										INNER JOIN [nFI].[Relational].AmexOffer o
											ON cal.IronOfferID = o.IronOfferID
										WHERE cal.PublisherType = 'AMEX'
										AND o.SegmentID <> 0
										AND o.SegmentID IS NOT NULL
										AND ame.ClickCounts > 0) c
								WHERE c.DateRank = 1
								GROUP BY	c.PartnerID
										,	c.StartDate
										,	c.EndDate
										,	c.PeriodType
								UNION ALL
								SELECT	z.PartnerID	-- AMEX Universal
									,	NULL AS PublisherID
									,	NULL AS OfferTypeForReports
									,	z.PeriodType
									,	z.StartDate
									,	z.EndDate
									,	SUM(z.Cardholders) AS Cardholders -- Sum over publishers
									,	'Retailer' AS [Grouping]
									,	@Today AS ReportDate
								FROM (	SELECT	c.PublisherID -- AMEX Universal
											,	c.PartnerID
											,	NULL AS OfferTypeForReports
											,	c.PeriodType
											,	c.StartDate
											,	c.EndDate
											,	MAX(c.ClickCounts) AS Cardholders -- Max per partner-publisher
											,	'Retailer' AS [Grouping]
										FROM (	SELECT	DISTINCT
														o.PublisherID
													,	cal.PartnerID
													,	cal.IronOfferID
													,	cal.PeriodType
													,	cal.StartDate
													,	cal.EndDate
													,	CASE WHEN (o.RetailerID = 4265 AND o.PublisherID = -1) THEN ame.ExposedCounts ELSE ame.ClickCounts END AS ClickCounts
													,	ROW_NUMBER() OVER (PARTITION BY cal.IronOfferID, cal.StartDate, cal.EndDate, cal.PeriodType ORDER BY DATEDIFF(day, ame.ReceivedDate, cal.EndDate) ASC) AS DateRank
												FROM #CalendarIO cal
												INNER JOIN [Warehouse].[APW].[AmexExposedClickCounts] ame
													ON cal.IronOfferID = ame.IronOfferID
													--AND DATEADD(day, 1, ame.ReceivedDate) <= cal.EndDate
												INNER JOIN [nFI].[Relational].[AmexOffer] o
													ON cal.IronOfferID = o.IronOfferID
												WHERE cal.PublisherType = 'AMEX'
												AND (o.SegmentID = 0 OR o.SegmentID IS NULL) -- Universal AMEX offers
												AND ame.ClickCounts > 0) c
										WHERE c.DateRank = 1
										GROUP BY	c.PublisherID
												,	c.PartnerID
												,	c.StartDate
												,	c.EndDate
												,	c.PeriodType) z
								GROUP BY	z.PartnerID
										,	z.PeriodType
										,	z.StartDate
										,	z.EndDate) y
						GROUP BY	y.PartnerID
								,	y.StartDate
								,	y.EndDate	
								,	y.PeriodType
								,	y.PublisherID
								,	y.OfferTypeForReports
								,	y.[Grouping]
								,	y.ReportDate) x
				GROUP BY	x.PartnerID
						,	x.StartDate
						,	x.EndDate	
						,	x.PeriodType
						,	x.PublisherID
						,	x.OfferTypeForReports			
						,	x.[Grouping]
						,	x.ReportDate;

			/*****************************
			Grouped by publisher
			*****************************/
	
				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts] (	RetailerID
																		,	PublisherID
																		,	OfferTypeForReports
																		,	PeriodType
																		,	StartDate
																		,	EndDate
																		,	Cardholders
																		,	[Grouping]
																		,	ReportDate)
				SELECT	x.PartnerID
					,	x.PublisherID
					,	x.OfferTypeForReports
					,	x.PeriodType
					,	x.StartDate
					,	x.EndDate		
					,	SUM(x.Cardholders) AS Cardholders
					,	x.[Grouping]
					,	x.ReportDate
				FROM (	SELECT	iom.PartnerID -- Warehouse / Virgin
							,	iom.PublisherID AS PublisherID
							,	NULL AS OfferTypeForReports
							,	iom.PeriodType
							,	iom.StartDate
							,	iom.EndDate
							,	COUNT(DISTINCT(iom.CompositeID)) AS Cardholders
							,	'RetailerPublisher' AS [Grouping]
							,	@Today AS ReportDate
						FROM #IronOfferMember iom
						GROUP BY	iom.PartnerID
								,	iom.PublisherID
								,	iom.StartDate
								,	iom.EndDate
								,	iom.PeriodType

						UNION ALL

						SELECT	iom.PartnerID -- nFI
							,	iom.PublisherID AS PublisherID
							,	NULL AS OfferTypeForReports
							,	iom.PeriodType
							,	iom.StartDate
							,	iom.EndDate
							,	COUNT(DISTINCT(iom.FanID)) AS Cardholders
							,	'RetailerPublisher' AS [Grouping]
							,	@Today AS ReportDate
						FROM #IronOfferMember iom
						GROUP BY	iom.PartnerID
								,	iom.PublisherID
								,	iom.StartDate
								,	iom.EndDate
								,	iom.PeriodType

						UNION ALL

						SELECT	y.PartnerID	-- Max AMEX cardholders (=clicks) (Non-Universal or Universal)
							,	y.PublisherID
							,	y.OfferTypeForReports
							,	y.PeriodType
							,	y.StartDate
							,	y.EndDate			
							,	MAX(y.Cardholders) AS Cardholders
							,	y.[Grouping]
							,	y.ReportDate
						FROM (	SELECT	c.PartnerID	-- AMEX Non-Universal
									,	c.PublisherID
									,	NULL AS OfferTypeForReports
									,	c.PeriodType
									,	c.StartDate
									,	c.EndDate
									,	SUM(c.ClickCounts) AS Cardholders
									,	'RetailerPublisher' AS [Grouping]
									,	@Today AS ReportDate
							FROM (	SELECT	DISTINCT
											cal.PartnerID
										,	o.PublisherID
										,	cal.IronOfferID
										,	cal.StartDate
										,	cal.EndDate
										,	cal.PeriodType
										,	CASE WHEN (o.RetailerID = 4265 AND o.PublisherID = -1) THEN ame.ExposedCounts ELSE ame.ClickCounts END AS ClickCounts
										,	ROW_NUMBER() OVER (PARTITION BY cal.IronOfferID, cal.StartDate, cal.EndDate, cal.PeriodType ORDER BY DATEDIFF(day, ame.ReceivedDate, cal.EndDate) ASC) AS DateRank
									FROM #CalendarIO cal
									INNER JOIN [Warehouse].[APW].[AmexExposedClickCounts] ame
										ON cal.IronOfferID = ame.IronOfferID
										--AND DATEADD(day, 1, ame.ReceivedDate) <= cal.EndDate
									INNER JOIN [nFI].[Relational].[AmexOffer] o
										ON cal.IronOfferID = o.IronOfferID
									WHERE cal.PublisherType = 'AMEX'
									AND o.SegmentID <> 0
									AND o.SegmentID IS NOT NULL
									AND ame.ClickCounts > 0) c
							WHERE c.DateRank = 1
							GROUP BY	c.PartnerID
									,	c.PublisherID
									,	c.StartDate
									,	c.EndDate
									,	c.PeriodType
							UNION ALL
							SELECT	c.PartnerID	-- AMEX Universal
								,	c.PublisherID
								,	NULL AS OfferTypeForReports
								,	c.PeriodType
								,	c.StartDate
								,	c.EndDate
								,	MAX(c.ClickCounts) AS Cardholders -- Max per partner-publisher
								,	'RetailerPublisher' AS [Grouping]
								,	@Today AS ReportDate
							FROM (	SELECT DISTINCT
											cal.PartnerID
										,	o.PublisherID
										,	cal.IronOfferID
										,	cal.PeriodType
										,	cal.StartDate
										,	cal.EndDate
										,	CASE WHEN (o.RetailerID = 4265 AND o.PublisherID = -1) THEN ame.ExposedCounts ELSE ame.ClickCounts END AS ClickCounts
										,	ROW_NUMBER() OVER (PARTITION BY cal.IronOfferID, cal.StartDate, cal.EndDate, cal.PeriodType ORDER BY DATEDIFF(day, ame.ReceivedDate, cal.EndDate) ASC) AS DateRank
									FROM #CalendarIO cal
									INNER JOIN [Warehouse].[APW].[AmexExposedClickCounts] ame
										ON cal.IronOfferID = ame.IronOfferID
										--AND DATEADD(day, 1, ame.ReceivedDate) <= cal.EndDate
									INNER JOIN [nFI].[Relational].[AmexOffer] o
										ON cal.IronOfferID = o.IronOfferID
									WHERE cal.PublisherType = 'AMEX'
									AND (o.SegmentID = 0 OR o.SegmentID IS NULL) -- Universal AMEX offers
									AND ame.ClickCounts > 0) c
							WHERE c.DateRank = 1
							GROUP BY	c.PartnerID
									,	c.PublisherID
									,	c.StartDate
									,	c.EndDate
									,	c.PeriodType) y
						GROUP BY	y.PartnerID
								,	y.StartDate
								,	y.EndDate	
								,	y.PeriodType
								,	y.PublisherID
								,	y.OfferTypeForReports
								,	y.[Grouping]
								,	y.ReportDate) x
				GROUP BY	x.PartnerID
						,	x.StartDate
						,	x.EndDate	
						,	x.PeriodType
						,	x.PublisherID
						,	x.OfferTypeForReports			
						,	x.[Grouping]
						,	x.ReportDate;

			/*****************************
			Grouped by segment
			*****************************/
	
				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts] (	RetailerID
																		,	PublisherID
																		,	OfferTypeForReports
																		,	PeriodType
																		,	StartDate
																		,	EndDate
																		,	Cardholders
																		,	[Grouping]
																		,	ReportDate)
				SELECT	x.PartnerID
					,	x.PublisherID
					,	x.OfferTypeForReports
					,	x.PeriodType
					,	x.StartDate
					,	x.EndDate		
					,	SUM(x.Cardholders) AS Cardholders
					,	x.[Grouping]
					,	x.ReportDate
				FROM (	SELECT	iom.PartnerID -- Warehouse / Virgin
							,	NULL AS PublisherID
							,	iom.OfferTypeForReports AS OfferTypeForReports
							,	iom.PeriodType
							,	iom.StartDate
							,	iom.EndDate
							,	COUNT(DISTINCT(iom.CompositeID)) AS Cardholders
							,	'RetailerOfferType' AS [Grouping]
							,	@Today AS ReportDate
						FROM #IronOfferMember iom
						GROUP BY	iom.PartnerID
								,	iom.OfferTypeForReports
								,	iom.StartDate
								,	iom.EndDate
								,	iom.PeriodType

						UNION ALL

						SELECT	iom.PartnerID -- nFI
							,	NULL AS PublisherID
							,	iom.OfferTypeForReports AS OfferTypeForReports
							,	iom.PeriodType
							,	iom.StartDate
							,	iom.EndDate
							,	COUNT(DISTINCT(iom.FanID)) AS Cardholders
							,	'RetailerOfferType' AS [Grouping]
							,	@Today AS ReportDate
						FROM #IronOfferMember iom
						GROUP BY	iom.PartnerID
								,	iom.OfferTypeForReports
								,	iom.StartDate
								,	iom.EndDate
								,	iom.PeriodType

						UNION ALL

						SELECT	y.PartnerID	-- Max AMEX cardholders (=clicks) (Non-Universal or Universal)
							,	y.PublisherID
							,	y.OfferTypeForReports
							,	y.PeriodType
							,	y.StartDate
							,	y.EndDate			
							,	MAX(y.Cardholders) AS Cardholders
							,	y.[Grouping]
							,	y.ReportDate
						FROM (	SELECT	c.PartnerID	-- AMEX Non-Universal
									,	NULL AS PublisherID
									,	c.OfferTypeForReports
									,	c.PeriodType
									,	c.StartDate
									,	c.EndDate
									,	SUM(c.ClickCounts) AS Cardholders
									,	'RetailerOfferType' AS [Grouping]
									,	@Today AS ReportDate
							FROM (	SELECT	DISTINCT
											cal.PartnerID
										,	cal.OfferTypeForReports
										,	cal.IronOfferID
										,	cal.StartDate
										,	cal.EndDate
										,	cal.PeriodType
										,	CASE WHEN (o.RetailerID = 4265 AND o.PublisherID = -1) THEN ame.ExposedCounts ELSE ame.ClickCounts END AS ClickCounts
										,	ROW_NUMBER() OVER (PARTITION BY cal.IronOfferID, cal.StartDate, cal.EndDate, cal.PeriodType ORDER BY DATEDIFF(day, ame.ReceivedDate, cal.EndDate) ASC) AS DateRank
									FROM #CalendarIO cal
									INNER JOIN [Warehouse].[APW].[AmexExposedClickCounts] ame
										ON cal.IronOfferID = ame.IronOfferID
										--AND DATEADD(day, 1, ame.ReceivedDate) <= cal.EndDate
									INNER JOIN [nFI].[Relational].[AmexOffer] o
										ON cal.IronOfferID = o.IronOfferID
									WHERE cal.PublisherType = 'AMEX'
									AND o.SegmentID <> 0
									AND o.SegmentID IS NOT NULL
									AND ame.ClickCounts > 0) c
							WHERE c.DateRank = 1
							GROUP BY	c.PartnerID
									,	c.OfferTypeForReports
									,	c.StartDate
									,	c.EndDate
									,	c.PeriodType
							UNION ALL
							SELECT	z.PartnerID	-- AMEX Universal
								,	NULL AS PublisherID
								,	z.OfferTypeForReports
								,	z.PeriodType
								,	z.StartDate
								,	z.EndDate
								,	SUM(z.Cardholders) AS Cardholders -- Sum over publishers
								,	'RetailerOfferType' AS [Grouping]
								,	@Today AS ReportDate
							FROM (	SELECT	c.PublisherID	-- AMEX Universal
										,	c.PartnerID
										,	c.OfferTypeForReports
										,	c.PeriodType
										,	c.StartDate
										,	c.EndDate
										,	MAX(c.ClickCounts) AS Cardholders -- Max per partner-publisher
										,	'RetailerOfferType' AS [Grouping]
									FROM (	SELECT	DISTINCT
													o.PublisherID
												,	cal.PartnerID
												,	cal.IronOfferID
												,	cal.OfferTypeForReports
												,	cal.PeriodType
												,	cal.StartDate
												,	cal.EndDate
												,	CASE WHEN (o.RetailerID = 4265 AND o.PublisherID = -1) THEN ame.ExposedCounts ELSE ame.ClickCounts END AS ClickCounts
												,	ROW_NUMBER() OVER (PARTITION BY cal.IronOfferID, cal.StartDate, cal.EndDate, cal.PeriodType ORDER BY DATEDIFF(day, ame.ReceivedDate, cal.EndDate) ASC) AS DateRank
											FROM #CalendarIO cal
											INNER JOIN [Warehouse].[APW].[AmexExposedClickCounts] ame
												ON cal.IronOfferID = ame.IronOfferID
												--AND DATEADD(day, 1, ame.ReceivedDate) <= cal.EndDate
											INNER JOIN [nFI].[Relational].[AmexOffer] o
												ON cal.IronOfferID = o.IronOfferID
											WHERE cal.PublisherType = 'AMEX'
											AND (o.SegmentID = 0 OR o.SegmentID IS NULL) -- Universal AMEX offers
											AND ame.ClickCounts >0) c
									WHERE c.DateRank = 1
									GROUP BY	c.PublisherID
											,	c.PartnerID
											,	c.StartDate
											,	c.EndDate
											,	c.PeriodType
											,	c.OfferTypeForReports) z
							GROUP BY	z.PartnerID
									,	z.OfferTypeForReports
									,	z.PeriodType
									,	z.StartDate
									,	z.EndDate) y
						GROUP BY	y.PartnerID
								,	y.StartDate
								,	y.EndDate	
								,	y.PeriodType
								,	y.PublisherID
								,	y.OfferTypeForReports
								,	y.[Grouping]
								,	y.ReportDate) x
				GROUP BY	x.PartnerID
						,	x.StartDate
						,	x.EndDate	
						,	x.PeriodType
						,	x.PublisherID
						,	x.OfferTypeForReports			
						,	x.[Grouping]
						,	x.ReportDate

				OPTION(RECOMPILE);

			SET @RowNum = @RowNum + 1;

		END -- End loop over retailers

END