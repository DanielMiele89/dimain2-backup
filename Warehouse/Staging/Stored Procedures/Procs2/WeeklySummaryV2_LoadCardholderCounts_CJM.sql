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

05/06/2022 CJM rewritten for performance.
******************************************************************************/
CREATE PROCEDURE [Staging].[WeeklySummaryV2_LoadCardholderCounts_CJM]
AS
BEGIN
	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON

	DECLARE @Time DATETIME
		  , @Msg VARCHAR(2048)
		  , @RowsProcessed INT 
		  , @SSMS BIT = 1 

	SET @Msg = 'WeeklySummaryV2_LoadCardholderCounts_CJM'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT



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
	SET @RowsProcessed = @@ROWCOUNT;
	SET @Msg = '#PartnerAlternate generated [' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows]'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT
	-- [113 rows] / 00:00:00

	/******************************************************************************
	Load customer table, following logic in APW.DirectLoad_Staging_Customer_Fetch stored procedure
	******************************************************************************/

		IF OBJECT_ID ('tempdb..#Customer') IS NOT NULL DROP TABLE #Customer;
		CREATE TABLE #Customer (FanID INT NOT NULL
							,	CompositeID BIGINT NOT NULL
							,	PublisherID INT NOT NULL
							,	ActivationDate DATE NOT NULL 
							,	DeactivationDate DATE)

		CREATE CLUSTERED INDEX cx_Stuff ON #Customer (CompositeID);
		CREATE NONCLUSTERED INDEX ix_Stuff ON #Customer (ActivationDate ASC, DeactivationDate ASC) INCLUDE (FanID);	


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
		SET @RowsProcessed = @@ROWCOUNT;
		SET @Msg = 'Warehouse customers [' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows]'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT
		-- [4,873,093 rows] / 00:07:29


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
		SET @RowsProcessed = @@ROWCOUNT;
		SET @Msg = 'nFI customers [' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows]'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT
		-- [6,312,831 rows] / 00:13:43

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
		SET @RowsProcessed = @@ROWCOUNT;
		SET @Msg = 'Virgin customers [' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows]'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT
		-- [397,164 rows] / 00:00:05

		-- Virgin PCA customers
		INSERT INTO #Customer (FanID, CompositeID, PublisherID, ActivationDate, DeactivationDate)	
		SELECT	cu.FanID
			,	cu.CompositeID
			,	cu.ClubID AS PublisherID
			,	cu.RegistrationDate AS ActivationDate
			,	cu.DeactivatedDate AS DeactivationDate
		FROM [WH_VirginPCA].[Derived].[Customer] cu;
		SET @RowsProcessed = @@ROWCOUNT;
		SET @Msg = 'Virgin PCA customers [' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows]'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT
		-- [128,824 rows] / 00:00:01

		-- Visa customers
		INSERT INTO #Customer (FanID, CompositeID, PublisherID, ActivationDate, DeactivationDate)
		SELECT	cu.FanID
			,	cu.CompositeID
			,	cu.ClubID AS PublisherID
			,	cu.RegistrationDate AS ActivationDate
			,	cu.DeactivatedDate AS DeactivationDate
		FROM [WH_Visa].[Derived].[Customer] cu;
		SET @RowsProcessed = @@ROWCOUNT;
		SET @Msg = 'Visa customers [' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows]'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT
		-- [183,738 rows] / 00:00:01

	/******************************************************************************
	Load cardholder table
	- Temp table contains duplicate customers if customers activate/deactivate multiple cards, but these are handled when distinct FanIDs/CompositeIDs are loaded later
	******************************************************************************/

		-- Fetch all Cardholders & their start / end dates

			IF OBJECT_ID ('tempdb..#CardHolderStaging') IS NOT NULL DROP TABLE #CardHolderStaging;
			SELECT	DISTINCT
					c.FanID

				,	c.CompositeID
				,	c.PublisherID
				,	CONVERT(DATE,	ISNULL(	CASE
												WHEN pc.AdditionDate > c.ActivationDate THEN pc.AdditionDate
												ELSE c.ActivationDate 
											END, '1900-01-01')) AS CardCustStartDate
				,	CONVERT(DATE,	ISNULL(	CASE
												WHEN (pc.RemovalDate < c.DeactivationDate OR c.DeactivationDate IS NULL) THEN pc.RemovalDate
												ELSE c.DeactivationDate 
											END, '9999-12-31')) AS CardCustEndDate
			INTO #CardHolderStaging
			FROM #Customer c
			INNER JOIN [SLC_Report].[dbo].[Pan] pc
				ON c.CompositeID = pc.CompositeID;
			SET @RowsProcessed = @@ROWCOUNT;

			CREATE CLUSTERED INDEX cx_Stuff ON #CardHolderStaging (CompositeID, CardCustStartDate, CardCustEndDate);
			SET @Msg = '#CardHolderStaging 1 [' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows]'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT
			-- [30,620,362 rows] / 00:01:03


			INSERT INTO #CardHolderStaging	--	Virgin
			SELECT	DISTINCT
					c.FanID
				,	c.CompositeID
				,	c.PublisherID
				,	ISNULL(c.ActivationDate, '1900-01-01') AS CardCustStartDate
				,	ISNULL(c.DeactivationDate, '9999-12-31') AS CardCustEndDate
			FROM #Customer c
			WHERE c.PublisherID = 166;
			SET @RowsProcessed = @@ROWCOUNT;
			SET @Msg = '#CardHolderStaging Virgin [' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows]'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT
			-- [397,164 rows] / 00:02:30

			INSERT INTO #CardHolderStaging	--	Virgin PCA
			SELECT	DISTINCT
					c.FanID
				,	c.CompositeID
				,	c.PublisherID
				,	ISNULL(c.ActivationDate, '1900-01-01') AS CardCustStartDate
				,	ISNULL(c.DeactivationDate, '9999-12-31') AS CardCustEndDate
			FROM #Customer c
			WHERE c.PublisherID = 182;
			SET @RowsProcessed = @@ROWCOUNT;
			SET @Msg = '#CardHolderStaging Virgin PCA [' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows]'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT
			-- [128824 rows] / 00:00:03

			INSERT INTO #CardHolderStaging	--	Visa Barclaycard
			SELECT	DISTINCT
					c.FanID
				,	c.CompositeID
				,	c.PublisherID
				,	ISNULL(c.ActivationDate, '1900-01-01') AS CardCustStartDate
				,	ISNULL(c.DeactivationDate, '9999-12-31') AS CardCustEndDate
			FROM #Customer c
			WHERE c.PublisherID = 180;
			SET @RowsProcessed = @@ROWCOUNT;
			SET @Msg = '#CardHolderStaging Visa Barclaycard [' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows]'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT
			-- [183738 rows] / 00:00:01


			DELETE
			FROM #CardHolderStaging
			WHERE CardCustStartDate > CardCustEndDate;
			SET @RowsProcessed = @@ROWCOUNT;
			SET @Msg = '#CardHolderStaging deletes [' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows]'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT
			-- [1328722 rows] / 00:00:15


		-- Consolidate overlapping date ranges
			IF OBJECT_ID ('tempdb..#CardHolder_Warehouse') IS NOT NULL DROP TABLE #CardHolder_Warehouse;
			SELECT	FanID
				,	CompositeID
				,	CardCustStartDate = MIN(ts)
				,	CardCustEndDate = MAX(ts)
			INTO #CardHolder_Warehouse
			FROM (	SELECT	FanID	-- f
						,	e.CompositeID
						,	e.ts
						,	RowPair = (1 + ROW_NUMBER() OVER(PARTITION BY CompositeID ORDER BY rn))/2 
					FROM (	SELECT	FanID	 -- e
								,	CompositeID
								,	ts
								,	[Type]
								,	RangeEnd
								,	rn
								,	RangeStart = SUM(d.[Type]) OVER (PARTITION BY d.CompositeID ORDER BY rn ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
							FROM (	SELECT	FanID	-- d
										,	CompositeID
										,	ts
										,	[Type]
										,	RangeEnd
										,	rn = ROW_NUMBER() OVER (PARTITION BY CompositeID ORDER BY ts DESC, [type], RangeEnd DESC)
									FROM (	SELECT	m.FanID	-- c
												,	m.CompositeID
												,	x.ts
												,	x.[Type]
												,	RangeEnd = SUM(x.[Type]) OVER (PARTITION BY m.CompositeID ORDER BY x.ts, x.[type] DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
											FROM #CardHolderStaging m
											CROSS APPLY (VALUES	(CardCustStartDate, 1)
															,	(CardCustEndDate, -1)) x (ts, [Type])
											WHERE m.PublisherID IN (132, 138)) c 
									) d
							) e 
					WHERE e.RangeEnd = 0
					OR e.RangeStart = 0) f
			GROUP BY	FanID
					,	CompositeID
					,	RowPair;
			SET @RowsProcessed = @@ROWCOUNT;

			CREATE CLUSTERED INDEX CIX_CompDates ON #CardHolder_Warehouse (CompositeID, CardCustStartDate, CardCustEndDate);
			SET @Msg = '#CardHolder_Warehouse generated and indexed [' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows]'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT
			-- [5,836,950 rows] / 00:01:23


			IF OBJECT_ID ('tempdb..#CardHolder_VirginAndVisaBarclaycard') IS NOT NULL DROP TABLE #CardHolder_VirginAndVisaBarclaycard;
			SELECT	FanID
				,	CompositeID
				,	CardCustStartDate = MIN(ts)
				,	CardCustEndDate = MAX(ts)
			INTO #CardHolder_VirginAndVisaBarclaycard
			FROM (	SELECT	FanID	-- f
						,	e.CompositeID
						,	e.ts
						,	RowPair = (1 + ROW_NUMBER() OVER(PARTITION BY CompositeID ORDER BY rn))/2 
					FROM (	SELECT	FanID	 -- e
								,	CompositeID
								,	ts
								,	[Type]
								,	RangeEnd
								,	rn
								,	RangeStart = SUM(d.[Type]) OVER (PARTITION BY d.CompositeID ORDER BY rn ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
							FROM (	SELECT	FanID	-- d
										,	CompositeID
										,	ts
										,	[Type]
										,	RangeEnd
										,	rn = ROW_NUMBER() OVER (PARTITION BY CompositeID ORDER BY ts DESC, [type], RangeEnd DESC)
									FROM (	SELECT	m.FanID	-- c
												,	m.CompositeID
												,	x.ts
												,	x.[Type]
												,	RangeEnd = SUM(x.[Type]) OVER (PARTITION BY m.CompositeID ORDER BY x.ts, x.[type] DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
											FROM #CardHolderStaging m
											CROSS APPLY (VALUES	(CardCustStartDate, 1)
															,	(CardCustEndDate, -1)) x (ts, [Type])
											WHERE m.PublisherID IN (166, 180, 182)) c 
									) d
							) e 
					WHERE e.RangeEnd = 0
					OR e.RangeStart = 0) f
			GROUP BY	FanID
					,	CompositeID
					,	RowPair;
			SET @RowsProcessed = @@ROWCOUNT;

			CREATE CLUSTERED INDEX CIX_CompDates ON #CardHolder_VirginAndVisaBarclaycard (CompositeID, CardCustStartDate, CardCustEndDate);
			SET @Msg = '#CardHolder_VirginAndVisaBarclaycard generated and indexed [' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows]'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT
			-- [709,665 rows] / 00:00:10


			IF OBJECT_ID ('tempdb..#CardHolder_nFI') IS NOT NULL DROP TABLE #CardHolder_nFI;
			SELECT 
				FanID, CompositeID,
				CardCustStartDate = MIN(ts),
				CardCustEndDate = MAX(ts)
			INTO #CardHolder_nFI
			FROM (-- f	
				SELECT	
					FanID, CompositeID, ts, RowPair = (1 + ROW_NUMBER() OVER(PARTITION BY CompositeID ORDER BY rn))/2 
				FROM (-- e	
					SELECT 
						FanID, CompositeID, ts, [Type], RangeEnd, rn, RangeStart = SUM(d.[Type]) OVER (PARTITION BY d.CompositeID ORDER BY rn ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
					FROM (-- d	
						SELECT 
							FanID, CompositeID, ts, [Type], RangeEnd, rn = ROW_NUMBER() OVER (PARTITION BY CompositeID ORDER BY ts DESC, [type], RangeEnd DESC)
						FROM ( -- c	
							SELECT 
								m.FanID, m.CompositeID, x.ts, x.[Type],	RangeEnd = SUM(x.[Type]) OVER (PARTITION BY m.CompositeID ORDER BY x.ts, x.[type] DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
							FROM #CardHolderStaging m
							CROSS APPLY (VALUES	
								(CardCustStartDate, 1),
								(CardCustEndDate, -1)
							) x (ts, [Type])
							WHERE m.PublisherID NOT IN (132, 138, 166, 180, 182)
						) c 
					) d
				) e 
				WHERE e.RangeEnd = 0 OR e.RangeStart = 0
			) f
			GROUP BY FanID, CompositeID, RowPair;
			SET @RowsProcessed = @@ROWCOUNT;

			CREATE CLUSTERED INDEX CIX_CompDates ON #CardHolder_nFI (FanID, CardCustStartDate, CardCustEndDate);
			SET @Msg = '#CardHolder_nFI generated and indexed [' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows]'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT
			-- [4,120,928 rows] / 00:00:42


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
		WHERE o.IsSignedOff = 1
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
		WHERE o.IsSignedOff = 1
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
		WHERE o.IsSignedOff = 1
		AND o.IronOfferName NOT LIKE 'Spare%' -- Exclude spare offers

		UNION ALL

		SELECT	cal.StartDate	-- Virgin PCA
			,	cal.EndDate
			,	cal.PeriodType
			,	o.IronOfferID
			,	s.OfferTypeForReports
			,	o.PartnerID
			,	'Virgin PCA' AS PublisherType
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
					FROM [WH_VirginPCA].[Derived].[IronOffer] o
					LEFT JOIN #PartnerAlternate pa
						ON o.PartnerID = pa.PartnerID) o	
			ON cal.RetailerID = o.PartnerID
			AND o.StartDate <= cal.EndDate
			AND (o.EndDate IS NULL OR o.EndDate >= cal.StartDate)
		LEFT JOIN [Warehouse].[Relational].[IronOfferSegment] s
			ON o.IronOfferID = s.IronOfferID
		WHERE o.IsSignedOff = 1
		AND o.IronOfferName NOT LIKE 'Spare%' -- Exclude spare offers

		UNION ALL

		SELECT	cal.StartDate	-- Visa Barclaycard
			,	cal.EndDate
			,	cal.PeriodType
			,	o.IronOfferID
			,	s.OfferTypeForReports
			,	o.PartnerID
			,	'Visa Barclaycard' AS PublisherType
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
					FROM [WH_Visa].[Derived].[IronOffer] o
					LEFT JOIN #PartnerAlternate pa
						ON o.PartnerID = pa.PartnerID) o	
			ON cal.RetailerID = o.PartnerID
			AND o.StartDate <= cal.EndDate
			AND (o.EndDate IS NULL OR o.EndDate >= cal.StartDate)
		LEFT JOIN [Warehouse].[Relational].[IronOfferSegment] s
			ON o.IronOfferID = s.IronOfferID
		WHERE o.IsSignedOff = 1
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
		SET @RowsProcessed = @@ROWCOUNT;

		CREATE CLUSTERED INDEX CIX_CalendarIOSetup ON #CalendarIOSetup (IronOfferID, StartDate, EndDate);
		
		SET @Msg = '#CalendarIOSetup generated and indexed [' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows]'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT
		-- [10892 rows] / 00:00:11


	/******************************************************************************
	Load distinct retailers to loop over
	******************************************************************************/

		IF OBJECT_ID ('tempdb..#Retailers') IS NOT NULL DROP TABLE #Retailers;

		SELECT	x.PartnerID
			,	ROW_NUMBER() OVER (ORDER BY x.PartnerID) AS RowNum
		INTO #Retailers
		FROM (	SELECT	DISTINCT RetailerID AS PartnerID
				FROM [Warehouse].Staging.WeeklySummaryV2_RetailerAnalysisPeriods) x;
		SET @RowsProcessed = @@ROWCOUNT;
		SET @Msg = 'Load distinct dates to loop over [' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows]'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT
		-- [34 rows] / 00:00:00



		IF OBJECT_ID ('tempdb..#Dates') IS NOT NULL DROP TABLE #Dates;
		SELECT	cs.StartDate
			,	cs.EndDate
			,	ROW_NUMBER() OVER (ORDER BY cs.StartDate, cs.EndDate) AS RowNum
		INTO #Dates
		FROM (	SELECT	DISTINCT
						StartDate
					,	EndDate
				FROM #CalendarIOSetup) cs
		SET @RowsProcessed = @@ROWCOUNT;
		SET @Msg = 'Load distinct retailers to loop over [' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows]'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT
		-- [34 rows] / 00:00:00


	/******************************************************************************
	Declare iteration variables
	******************************************************************************/

		DECLARE @RowNum int;
		DECLARE @MaxRowNum int;
		DECLARE @PartnerID int;
		DECLARE @StartDate DATE;
		DECLARE @EndDate DATE;

		SET @RowNum = 1;
		SET @MaxRowNum = (SELECT MAX(RowNum) FROM #Dates);

	/******************************************************************************
	Begin loop: iterate over retailers
	******************************************************************************/

		WHILE @RowNum <= @MaxRowNum BEGIN

			/*****************************
			Prepare calendar table for individual partner
			*****************************/
				SELECT	@StartDate = StartDate
					,	@EndDate = EndDate
				FROM #Dates
				WHERE RowNum = @RowNum


				IF OBJECT_ID ('tempdb..#CalendarIO_Warehouse') IS NOT NULL DROP TABLE #CalendarIO_Warehouse;
				SELECT	s.StartDate
					,	s.EndDate
					,	s.PeriodType
					,	s.IronOfferID
					,	s.OfferTypeForReports
					,	s.PartnerID
					,	s.PublisherType
					,	s.PublisherID
				INTO #CalendarIO_Warehouse
				FROM #CalendarIOSetup s
				WHERE s.PublisherType = 'Warehouse'
				AND s.StartDate = @StartDate
				AND s.EndDate = @EndDate;

				IF OBJECT_ID ('tempdb..#CalendarIO_Virgin') IS NOT NULL DROP TABLE #CalendarIO_Virgin;
				SELECT	s.StartDate
					,	s.EndDate
					,	s.PeriodType
					,	s.IronOfferID
					,	s.OfferTypeForReports
					,	s.PartnerID
					,	s.PublisherType
					,	s.PublisherID
				INTO #CalendarIO_Virgin
				FROM #CalendarIOSetup s
				WHERE s.PublisherType = 'Virgin'
				AND s.StartDate = @StartDate
				AND s.EndDate = @EndDate;

				IF OBJECT_ID ('tempdb..#CalendarIO_VirginPCA') IS NOT NULL DROP TABLE #CalendarIO_VirginPCA;
				SELECT	s.StartDate
					,	s.EndDate
					,	s.PeriodType
					,	s.IronOfferID
					,	s.OfferTypeForReports
					,	s.PartnerID
					,	s.PublisherType
					,	s.PublisherID
				INTO #CalendarIO_VirginPCA
				FROM #CalendarIOSetup s
				WHERE s.PublisherType = 'Virgin PCA'
				AND s.StartDate = @StartDate
				AND s.EndDate = @EndDate;

				IF OBJECT_ID ('tempdb..#CalendarIO_VisaBarclaycard') IS NOT NULL DROP TABLE #CalendarIO_VisaBarclaycard;
				SELECT	s.StartDate
					,	s.EndDate
					,	s.PeriodType
					,	s.IronOfferID
					,	s.OfferTypeForReports
					,	s.PartnerID
					,	s.PublisherType
					,	s.PublisherID
				INTO #CalendarIO_VisaBarclaycard
				FROM #CalendarIOSetup s
				WHERE s.PublisherType = 'Visa Barclaycard'
				AND s.StartDate = @StartDate
				AND s.EndDate = @EndDate;

				IF OBJECT_ID ('tempdb..#CalendarIO_nFI') IS NOT NULL DROP TABLE #CalendarIO_nFI;
				SELECT	s.StartDate
					,	s.EndDate
					,	s.PeriodType
					,	s.IronOfferID
					,	s.OfferTypeForReports
					,	s.PartnerID
					,	s.PublisherType
					,	s.PublisherID
				INTO #CalendarIO_nFI
				FROM #CalendarIOSetup s
				WHERE s.PublisherType = 'nFI'
				AND s.StartDate = @StartDate
				AND s.EndDate = @EndDate;

				IF OBJECT_ID ('tempdb..#CalendarIO_AMEX') IS NOT NULL DROP TABLE #CalendarIO_AMEX;
				SELECT	s.StartDate
					,	s.EndDate
					,	s.PeriodType
					,	s.IronOfferID
					,	s.OfferTypeForReports
					,	s.PartnerID
					,	s.PublisherType
					,	s.PublisherID
				INTO #CalendarIO_AMEX
				FROM #CalendarIOSetup s
				WHERE s.StartDate = @StartDate
				AND s.EndDate = @EndDate
				AND s.PublisherType = 'AMEX'
				AND s.StartDate = @StartDate
				AND s.EndDate = @EndDate;

				CREATE CLUSTERED INDEX CIX_CalendarIO ON #CalendarIO_Warehouse (IronOfferID, StartDate, EndDate);
				CREATE CLUSTERED INDEX CIX_CalendarIO ON #CalendarIO_Virgin (IronOfferID, StartDate, EndDate);
				CREATE CLUSTERED INDEX CIX_CalendarIO ON #CalendarIO_VirginPCA (IronOfferID, StartDate, EndDate);
				CREATE CLUSTERED INDEX CIX_CalendarIO ON #CalendarIO_VisaBarclaycard (IronOfferID, StartDate, EndDate);
				CREATE CLUSTERED INDEX CIX_CalendarIO ON #CalendarIO_nFI (IronOfferID, StartDate, EndDate);
				CREATE CLUSTERED INDEX CIX_CalendarIO ON #CalendarIO_AMEX (IronOfferID, StartDate, EndDate);

				CREATE NONCLUSTERED INDEX IX_CalendarIO ON #CalendarIO_Warehouse (PublisherType, PublisherID, OfferTypeForReports);
				CREATE NONCLUSTERED INDEX IX_CalendarIO ON #CalendarIO_Virgin (PublisherType, PublisherID, OfferTypeForReports);
				CREATE NONCLUSTERED INDEX IX_CalendarIO ON #CalendarIO_VirginPCA (PublisherType, PublisherID, OfferTypeForReports);
				CREATE NONCLUSTERED INDEX IX_CalendarIO ON #CalendarIO_VisaBarclaycard (PublisherType, PublisherID, OfferTypeForReports);
				CREATE NONCLUSTERED INDEX IX_CalendarIO ON #CalendarIO_nFI (PublisherType, PublisherID, OfferTypeForReports);
				CREATE NONCLUSTERED INDEX IX_CalendarIO ON #CalendarIO_AMEX (PublisherType, PublisherID, OfferTypeForReports);
				
			/******************************************************************************
			Load rows into cardholder counts table
			1 Overall
			2 Grouped by publisher
			3 Grouped by segment
			******************************************************************************/
	



				/*****************************
				Overall 
				*****************************/

				DECLARE	@Grouping VARCHAR(25) = 'Retailer',
						@Today DATE = GETDATE()


				TRUNCATE TABLE [Staging].[WeeklySummaryV2_CardholderCounts_Interim]


				--	Warehouse
				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	
					RetailerID,	PublisherID, OfferTypeForReports, PeriodType, StartDate, EndDate, Cardholders, [Grouping], ReportDate)	
				SELECT	PartnerID = cal.PartnerID
					,	PublisherID = NULL			--	NULL / cal.PublisherID
					,	OfferTypeForReports = NULL	--	NULL / cal.OfferTypeForReports
					,	PeriodType = cal.PeriodType
					,	StartDate = cal.StartDate
					,	EndDate = cal.EndDate
					,	Cardholders = COUNT(DISTINCT iom.CompositeID)
					,	[Grouping] = @Grouping
					,	ReportDate = @Today
				FROM #CalendarIO_Warehouse cal
				CROSS APPLY (	SELECT	iom.CompositeID
								FROM [Warehouse].[Relational].[IronOfferMember] iom
								WHERE cal.IronOfferID = iom.IronOfferID
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_Warehouse ch
												WHERE iom.CompositeID = ch.CompositeID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY cal.PartnerID, --cal.PublisherID, cal.OfferTypeForReports,
					cal.PeriodType, cal.StartDate, cal.EndDate


				--	Virgin
				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	
					RetailerID,	PublisherID, OfferTypeForReports, PeriodType, StartDate, EndDate, Cardholders, [Grouping], ReportDate)	
				SELECT	PartnerID = cal.PartnerID
					,	PublisherID = NULL			--	NULL / cal.PublisherID
					,	OfferTypeForReports = NULL	--	NULL / cal.OfferTypeForReports
					,	PeriodType = cal.PeriodType
					,	StartDate = cal.StartDate
					,	EndDate = cal.EndDate
					,	Cardholders = COUNT(DISTINCT iom.CompositeID)
					,	[Grouping] = @Grouping
					,	ReportDate = @Today
				FROM #CalendarIO_Virgin cal
				CROSS APPLY (	SELECT	iom.CompositeID
								FROM [WH_Virgin].[Derived].[IronOfferMember] iom
								WHERE cal.IronOfferID = iom.IronOfferID
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_VirginAndVisaBarclaycard ch
												WHERE iom.CompositeID = ch.CompositeID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY cal.PartnerID, --cal.PublisherID, cal.OfferTypeForReports,
					cal.PeriodType, cal.StartDate, cal.EndDate


				--	Virgin PCA
				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	
					RetailerID,	PublisherID, OfferTypeForReports, PeriodType, StartDate, EndDate, Cardholders, [Grouping], ReportDate)	
				SELECT	PartnerID = cal.PartnerID
					,	PublisherID = NULL			--	NULL / cal.PublisherID
					,	OfferTypeForReports = NULL	--	NULL / cal.OfferTypeForReports
					,	PeriodType = cal.PeriodType
					,	StartDate = cal.StartDate
					,	EndDate = cal.EndDate
					,	Cardholders = COUNT(DISTINCT iom.CompositeID)
					,	[Grouping] = @Grouping
					,	ReportDate = @Today
				FROM #CalendarIO_VirginPCA cal
				CROSS APPLY (	SELECT	iom.CompositeID
								FROM [WH_VirginPCA].[Derived].[IronOfferMember] iom
								WHERE cal.IronOfferID = iom.IronOfferID
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_VirginAndVisaBarclaycard ch
												WHERE iom.CompositeID = ch.CompositeID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY cal.PartnerID, --cal.PublisherID, cal.OfferTypeForReports,
					cal.PeriodType, cal.StartDate, cal.EndDate


				--	Visa Barclaycard
				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	
					RetailerID,	PublisherID, OfferTypeForReports, PeriodType, StartDate, EndDate, Cardholders, [Grouping], ReportDate)	
				SELECT	PartnerID = cal.PartnerID
					,	PublisherID = NULL			--	NULL / cal.PublisherID
					,	OfferTypeForReports = NULL	--	NULL / cal.OfferTypeForReports
					,	PeriodType = cal.PeriodType
					,	StartDate = cal.StartDate
					,	EndDate = cal.EndDate
					,	Cardholders = COUNT(DISTINCT iom.CompositeID)
					,	[Grouping] = @Grouping
					,	ReportDate = @Today
				FROM #CalendarIO_VisaBarclaycard cal
				CROSS APPLY (	SELECT	iom.CompositeID
								FROM [WH_Visa].[Derived].[IronOfferMember] iom
								WHERE cal.IronOfferID = iom.IronOfferID
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_VirginAndVisaBarclaycard ch
												WHERE iom.CompositeID = ch.CompositeID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY cal.PartnerID, --cal.PublisherID, cal.OfferTypeForReports,
					cal.PeriodType, cal.StartDate, cal.EndDate


				--	nFI
				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	
					RetailerID,	PublisherID, OfferTypeForReports, PeriodType, StartDate, EndDate, Cardholders, [Grouping], ReportDate)	
				SELECT	PartnerID = cal.PartnerID
					,	PublisherID = NULL			--	NULL / cal.PublisherID
					,	OfferTypeForReports = NULL	--	NULL / cal.OfferTypeForReports
					,	PeriodType = cal.PeriodType
					,	StartDate = cal.StartDate
					,	EndDate = cal.EndDate
					,	Cardholders = COUNT(DISTINCT iom.FanID)
					,	[Grouping] = @Grouping
					,	ReportDate = @Today
				FROM #CalendarIO_nFI cal
				CROSS APPLY (	SELECT	iom.FanID
								FROM [nFI].[Relational].[IronOfferMember] iom
								WHERE cal.IronOfferID = iom.IronOfferID
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_nFI ch
												WHERE iom.FanID = ch.FanID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY cal.PartnerID, --cal.PublisherID, cal.OfferTypeForReports,
					cal.PeriodType, cal.StartDate, cal.EndDate


				--	AMEX
				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	
					RetailerID,	PublisherID, OfferTypeForReports, PeriodType, StartDate, EndDate, Cardholders, [Grouping], ReportDate)	
				SELECT	y.PartnerID
					,	y.PublisherID
					,	y.OfferTypeForReports
					,	y.PeriodType
					,	y.StartDate
					,	y.EndDate
					,	Cardholders = MAX(y.Cardholders)
					,	[Grouping] = @Grouping
					,	ReportDate = @Today
				FROM (	SELECT	c.PartnerID	-- AMEX Non-Universal
							,	c.PublisherID
							,	c.OfferTypeForReports
							,	c.PeriodType
							,	c.StartDate
							,	c.EndDate
							,	SUM(c.ClickCounts) AS Cardholders
						FROM (	SELECT	DISTINCT
										cal.PartnerID
									,	PublisherID = NULL			--	NULL / cal.PublisherID
									,	OfferTypeForReports = NULL	--	NULL / cal.OfferTypeForReports
									,	cal.IronOfferID
									,	cal.StartDate
									,	cal.EndDate
									,	cal.PeriodType
									,	CASE WHEN (o.RetailerID = 4265 AND o.PublisherID = -1) THEN ame.ExposedCounts ELSE ame.ClickCounts END AS ClickCounts
									,	ROW_NUMBER() OVER (PARTITION BY cal.IronOfferID, cal.StartDate, cal.EndDate, cal.PeriodType ORDER BY DATEDIFF(day, ame.ReceivedDate, cal.EndDate) ASC) AS DateRank
								FROM #CalendarIO_AMEX cal
								INNER JOIN [Warehouse].[APW].[AmexExposedClickCounts] ame
									ON cal.IronOfferID = ame.IronOfferID
								INNER JOIN [nFI].[Relational].AmexOffer o
									ON cal.IronOfferID = o.IronOfferID
								WHERE o.SegmentID <> 0
								AND o.SegmentID IS NOT NULL
								AND ame.ClickCounts > 0) c
						WHERE c.DateRank = 1
						GROUP BY	c.PartnerID
								,	c.PublisherID
								,	c.OfferTypeForReports
								,	c.StartDate
								,	c.EndDate
								,	c.PeriodType

						UNION ALL

						SELECT	z.PartnerID	-- AMEX Universal
							,	PublisherID = NULL				--	NULL / z.PublisherID
							,	OfferTypeForReports = NULL		--	NULL / z.OfferTypeForReports
							,	z.PeriodType
							,	z.StartDate
							,	z.EndDate
							,	SUM(z.Cardholders) AS Cardholders -- Sum over publishers
						FROM (	SELECT	PartnerID = c.PartnerID	-- AMEX Universal
									,	PublisherID = c.PublisherID
									,	OfferTypeForReports = c.OfferTypeForReports
									,	PeriodType = c.PeriodType
									,	StartDate = c.StartDate
									,	EndDate = c.EndDate
									,	Cardholders = MAX(c.ClickCounts)
								FROM (	SELECT	DISTINCT
												cal.PartnerID
											,	PublisherID = o.PublisherID
											,	OfferTypeForReports = NULL		--	NULL / o.OfferTypeForReports
											,	cal.IronOfferID
											,	cal.PeriodType
											,	cal.StartDate
											,	cal.EndDate
											,	CASE WHEN (o.RetailerID = 4265 AND o.PublisherID = -1) THEN ame.ExposedCounts ELSE ame.ClickCounts END AS ClickCounts
											,	ROW_NUMBER() OVER (PARTITION BY cal.IronOfferID, cal.StartDate, cal.EndDate, cal.PeriodType ORDER BY DATEDIFF(day, ame.ReceivedDate, cal.EndDate) ASC) AS DateRank
										FROM #CalendarIO_AMEX cal
										INNER JOIN [Warehouse].[APW].[AmexExposedClickCounts] ame
											ON cal.IronOfferID = ame.IronOfferID
											--AND DATEADD(day, 1, ame.ReceivedDate) <= cal.EndDate
										INNER JOIN [nFI].[Relational].[AmexOffer] o
											ON cal.IronOfferID = o.IronOfferID
										WHERE (o.SegmentID = 0 OR o.SegmentID IS NULL) -- Universal AMEX offers
										AND ame.ClickCounts > 0) c
								WHERE c.DateRank = 1
								GROUP BY	c.PartnerID
										,	c.PublisherID
										,	c.OfferTypeForReports
										,	c.StartDate
										,	c.EndDate
										,	c.PeriodType) z
						GROUP BY	z.PartnerID
							--	,	z.PublisherID
							--	,	z.OfferTypeForReports
								,	z.PeriodType
								,	z.StartDate
								,	z.EndDate) y
				GROUP BY	y.PartnerID
						,	y.PublisherID
						,	y.OfferTypeForReports
						,	y.StartDate
						,	y.EndDate	
						,	y.PeriodType
						,	y.PublisherID
						,	y.OfferTypeForReports


				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_CJM] (	
					RetailerID, PublisherID, OfferTypeForReports, PeriodType, StartDate, EndDate, [Grouping], ReportDate,	
					Cardholders)
				SELECT 
					RetailerID, PublisherID, OfferTypeForReports, PeriodType, StartDate, EndDate, [Grouping], ReportDate,	
					Cardholders = SUM(Cardholders)
				FROM [Staging].[WeeklySummaryV2_CardholderCounts_Interim] 
				GROUP BY 
					RetailerID, PublisherID, OfferTypeForReports, PeriodType, StartDate, EndDate, [Grouping], ReportDate



				/*****************************
				Grouped by publisher ##########################################################################################
				*****************************/
				SET @Grouping = 'RetailerPublisher'

				TRUNCATE TABLE [Staging].[WeeklySummaryV2_CardholderCounts_Interim]

				--	Warehouse
				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	
					RetailerID,	PublisherID, OfferTypeForReports, PeriodType, StartDate, EndDate, Cardholders, [Grouping], ReportDate)	
				SELECT	PartnerID = cal.PartnerID
					,	PublisherID = cal.PublisherID	--	NULL / cal.PublisherID
					,	OfferTypeForReports = NULL		--	NULL / cal.OfferTypeForReports
					,	PeriodType = cal.PeriodType
					,	StartDate = cal.StartDate
					,	EndDate = cal.EndDate
					,	Cardholders = COUNT(DISTINCT iom.CompositeID)
					,	[Grouping] = @Grouping
					,	ReportDate = @Today
				FROM #CalendarIO_Warehouse cal
				CROSS APPLY (	SELECT	iom.CompositeID
								FROM [Warehouse].[Relational].[IronOfferMember] iom
								WHERE cal.IronOfferID = iom.IronOfferID
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_Warehouse ch
												WHERE iom.CompositeID = ch.CompositeID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY cal.PartnerID, cal.PublisherID, --cal.OfferTypeForReports,
					cal.PeriodType, cal.StartDate, cal.EndDate 


				--	Virgin
				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	
					RetailerID,	PublisherID, OfferTypeForReports, PeriodType, StartDate, EndDate, Cardholders, [Grouping], ReportDate)	
				SELECT	PartnerID = cal.PartnerID
					,	PublisherID = cal.PublisherID	--	NULL / cal.PublisherID
					,	OfferTypeForReports = NULL		--	NULL / cal.OfferTypeForReports
					,	PeriodType = cal.PeriodType
					,	StartDate = cal.StartDate
					,	EndDate = cal.EndDate
					,	Cardholders = COUNT(DISTINCT iom.CompositeID)
					,	[Grouping] = @Grouping
					,	ReportDate = @Today
				FROM #CalendarIO_Virgin cal
				CROSS APPLY (	SELECT	iom.CompositeID
								FROM [WH_Virgin].[Derived].[IronOfferMember] iom
								WHERE cal.IronOfferID = iom.IronOfferID
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_VirginAndVisaBarclaycard ch
												WHERE iom.CompositeID = ch.CompositeID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY cal.PartnerID, cal.PublisherID, --cal.OfferTypeForReports,
					cal.PeriodType, cal.StartDate, cal.EndDate 


				--	Virgin PCA
				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	
					RetailerID,	PublisherID, OfferTypeForReports, PeriodType, StartDate, EndDate, Cardholders, [Grouping], ReportDate)	
				SELECT	PartnerID = cal.PartnerID
					,	PublisherID = cal.PublisherID	--	NULL / cal.PublisherID
					,	OfferTypeForReports = NULL		--	NULL / cal.OfferTypeForReports
					,	PeriodType = cal.PeriodType
					,	StartDate = cal.StartDate
					,	EndDate = cal.EndDate
					,	Cardholders = COUNT(DISTINCT iom.CompositeID)
					,	[Grouping] = @Grouping
					,	ReportDate = @Today
				FROM #CalendarIO_VirginPCA cal
				CROSS APPLY (	SELECT	iom.CompositeID
								FROM [WH_VirginPCA].[Derived].[IronOfferMember] iom
								WHERE cal.IronOfferID = iom.IronOfferID
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_VirginAndVisaBarclaycard ch
												WHERE iom.CompositeID = ch.CompositeID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY cal.PartnerID, cal.PublisherID, --cal.OfferTypeForReports,
					cal.PeriodType, cal.StartDate, cal.EndDate 


				--	Visa Barclaycard
				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	
					RetailerID,	PublisherID, OfferTypeForReports, PeriodType, StartDate, EndDate, Cardholders, [Grouping], ReportDate)	
				SELECT	PartnerID = cal.PartnerID
					,	PublisherID = cal.PublisherID	--	NULL / cal.PublisherID
					,	OfferTypeForReports = NULL		--	NULL / cal.OfferTypeForReports
					,	PeriodType = cal.PeriodType
					,	StartDate = cal.StartDate
					,	EndDate = cal.EndDate
					,	Cardholders = COUNT(DISTINCT iom.CompositeID)
					,	[Grouping] = @Grouping
					,	ReportDate = @Today
				FROM #CalendarIO_VisaBarclaycard cal
				CROSS APPLY (	SELECT	iom.CompositeID
								FROM [WH_Visa].[Derived].[IronOfferMember] iom
								WHERE cal.IronOfferID = iom.IronOfferID
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_VirginAndVisaBarclaycard ch
												WHERE iom.CompositeID = ch.CompositeID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY cal.PartnerID, cal.PublisherID, --cal.OfferTypeForReports,
					cal.PeriodType, cal.StartDate, cal.EndDate 

				
				--	nFI
				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	
					RetailerID,	PublisherID, OfferTypeForReports, PeriodType, StartDate, EndDate, Cardholders, [Grouping], ReportDate)		
				SELECT	PartnerID = cal.PartnerID
					,	PublisherID = cal.PublisherID	--	NULL / cal.PublisherID
					,	OfferTypeForReports = NULL		--	NULL / cal.OfferTypeForReports
					,	PeriodType = cal.PeriodType
					,	StartDate = cal.StartDate
					,	EndDate = cal.EndDate
					,	Cardholders = COUNT(DISTINCT iom.FanID)
					,	[Grouping] = @Grouping
					,	ReportDate = @Today
				FROM #CalendarIO_nFI cal
				CROSS APPLY (	SELECT	iom.FanID
								FROM [nFI].[Relational].[IronOfferMember] iom
								WHERE cal.IronOfferID = iom.IronOfferID
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_nFI ch
												WHERE iom.FanID = ch.FanID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY cal.PartnerID, cal.PublisherID, --cal.OfferTypeForReports,
					cal.PeriodType, cal.StartDate, cal.EndDate 


				-- --	AMEX
				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	
					RetailerID,	PublisherID, OfferTypeForReports, PeriodType, StartDate, EndDate, Cardholders, [Grouping], ReportDate)				
				SELECT	y.PartnerID
					,	y.PublisherID
					,	y.OfferTypeForReports
					,	y.PeriodType
					,	y.StartDate
					,	y.EndDate
					,	Cardholders = MAX(y.Cardholders)
					,	[Grouping] = @Grouping
					,	ReportDate = @Today
				FROM (	SELECT	c.PartnerID	-- AMEX Non-Universal
							,	c.PublisherID
							,	c.OfferTypeForReports
							,	c.PeriodType
							,	c.StartDate
							,	c.EndDate
							,	SUM(c.ClickCounts) AS Cardholders
						FROM (	SELECT	DISTINCT
										cal.PartnerID
									,	PublisherID = cal.PublisherID	--	NULL / cal.PublisherID
									,	OfferTypeForReports = NULL		--	NULL / cal.OfferTypeForReports
									,	cal.IronOfferID
									,	cal.StartDate
									,	cal.EndDate
									,	cal.PeriodType
									,	CASE WHEN (o.RetailerID = 4265 AND o.PublisherID = -1) THEN ame.ExposedCounts ELSE ame.ClickCounts END AS ClickCounts
									,	ROW_NUMBER() OVER (PARTITION BY cal.IronOfferID, cal.StartDate, cal.EndDate, cal.PeriodType ORDER BY DATEDIFF(day, ame.ReceivedDate, cal.EndDate) ASC) AS DateRank
								FROM #CalendarIO_AMEX cal
								INNER JOIN [Warehouse].[APW].[AmexExposedClickCounts] ame
									ON cal.IronOfferID = ame.IronOfferID
								INNER JOIN [nFI].[Relational].AmexOffer o
									ON cal.IronOfferID = o.IronOfferID
								WHERE o.SegmentID <> 0
								AND o.SegmentID IS NOT NULL
								AND ame.ClickCounts > 0) c
						WHERE c.DateRank = 1
						GROUP BY	c.PartnerID
								,	c.PublisherID
								,	c.OfferTypeForReports
								,	c.StartDate
								,	c.EndDate
								,	c.PeriodType

						UNION ALL

						SELECT	z.PartnerID	-- AMEX Universal
							,	PublisherID = z.PublisherID		--	NULL / z.PublisherID
							,	OfferTypeForReports = NULL		--	NULL / z.OfferTypeForReports
							,	z.PeriodType
							,	z.StartDate
							,	z.EndDate
							,	SUM(z.Cardholders) AS Cardholders -- Sum over publishers
						FROM (	SELECT	PartnerID = c.PartnerID	-- AMEX Universal
									,	PublisherID = c.PublisherID
									,	OfferTypeForReports = c.OfferTypeForReports
									,	PeriodType = c.PeriodType
									,	StartDate = c.StartDate
									,	EndDate = c.EndDate
									,	Cardholders = MAX(c.ClickCounts)
								FROM (	SELECT	DISTINCT
												cal.PartnerID
											,	PublisherID = o.PublisherID
											,	OfferTypeForReports = NULL		--	NULL / o.OfferTypeForReports
											,	cal.IronOfferID
											,	cal.PeriodType
											,	cal.StartDate
											,	cal.EndDate
											,	CASE WHEN (o.RetailerID = 4265 AND o.PublisherID = -1) THEN ame.ExposedCounts ELSE ame.ClickCounts END AS ClickCounts
											,	ROW_NUMBER() OVER (PARTITION BY cal.IronOfferID, cal.StartDate, cal.EndDate, cal.PeriodType ORDER BY DATEDIFF(day, ame.ReceivedDate, cal.EndDate) ASC) AS DateRank
										FROM #CalendarIO_AMEX cal
										INNER JOIN [Warehouse].[APW].[AmexExposedClickCounts] ame
											ON cal.IronOfferID = ame.IronOfferID
											--AND DATEADD(day, 1, ame.ReceivedDate) <= cal.EndDate
										INNER JOIN [nFI].[Relational].[AmexOffer] o
											ON cal.IronOfferID = o.IronOfferID
										WHERE (o.SegmentID = 0 OR o.SegmentID IS NULL) -- Universal AMEX offers
										AND ame.ClickCounts > 0) c
								WHERE c.DateRank = 1
								GROUP BY	c.PartnerID
										,	c.PublisherID
										,	c.OfferTypeForReports
										,	c.StartDate
										,	c.EndDate
										,	c.PeriodType) z
						GROUP BY	z.PartnerID
								,	z.PublisherID
							--	,	z.OfferTypeForReports
								,	z.PeriodType
								,	z.StartDate
								,	z.EndDate) y
				GROUP BY y.PartnerID, y.PublisherID, y.OfferTypeForReports,	y.PeriodType,	y.StartDate,	y.EndDate	



				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_CJM] (	
					RetailerID, PublisherID, OfferTypeForReports, PeriodType, StartDate, EndDate, [Grouping], ReportDate,	
					Cardholders)
				SELECT 
					RetailerID, PublisherID, OfferTypeForReports, PeriodType, StartDate, EndDate, [Grouping], ReportDate,	
					Cardholders = SUM(Cardholders)
				FROM [Staging].[WeeklySummaryV2_CardholderCounts_Interim] 
				GROUP BY 
					RetailerID, PublisherID, OfferTypeForReports, PeriodType, StartDate, EndDate, [Grouping], ReportDate



				/*****************************
				Grouped by segment 
				*****************************/
				SET @Grouping = 'RetailerOfferType'

				TRUNCATE TABLE [Staging].[WeeklySummaryV2_CardholderCounts_Interim]


				-- RetailerID	--	Warehouse
				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	
					RetailerID,	PublisherID, OfferTypeForReports, PeriodType, StartDate, EndDate, Cardholders, [Grouping], ReportDate)				
				SELECT
					cal.PartnerID,
					PublisherID = NULL,
					cal.OfferTypeForReports,
					cal.PeriodType,
					cal.StartDate,
					cal.EndDate,
					Cardholders = COUNT(*),  
					[Grouping] = @Grouping,
					ReportDate = @Today
				FROM #CalendarIO_Warehouse cal
				INNER JOIN #CardHolder_Warehouse ch
					ON ch.CardCustStartDate <= cal.EndDate
					AND ch.CardCustEndDate >= cal.StartDate
				
				INNER JOIN [Warehouse].[Relational].[IronOfferMember] iom 				 
					ON iom.IronOfferID = cal.IronOfferID
					AND iom.CompositeID = ch.CompositeID
					AND iom.StartDate <= cal.EndDate
					AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)

				GROUP BY cal.PartnerID, cal.OfferTypeForReports, 
					cal.PeriodType, cal.StartDate, cal.EndDate


				-- RetailerID	--	Virgin
				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	
					RetailerID,	PublisherID, OfferTypeForReports, PeriodType, StartDate, EndDate, Cardholders, [Grouping], ReportDate)
				SELECT	cal.PartnerID,
						PublisherID = NULL,								
						cal.OfferTypeForReports,	
						cal.PeriodType,
						cal.StartDate,
						cal.EndDate,
						Cardholders = COUNT(DISTINCT iom.CompositeID),
						[Grouping] = @Grouping,
						ReportDate = @Today
				FROM #CalendarIO_Virgin cal
				CROSS APPLY (	SELECT	iom.CompositeID
								FROM [WH_Virgin].[Derived].[IronOfferMember] iom
								WHERE cal.IronOfferID = iom.IronOfferID
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_VirginAndVisaBarclaycard ch
												WHERE iom.CompositeID = ch.CompositeID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY cal.PartnerID, cal.OfferTypeForReports, 
					cal.PeriodType, cal.StartDate, cal.EndDate


				-- RetailerID	--	Virgin PCA
				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	
					RetailerID,	PublisherID, OfferTypeForReports, PeriodType, StartDate, EndDate, Cardholders, [Grouping], ReportDate)
				SELECT	cal.PartnerID,
						PublisherID = NULL,								
						cal.OfferTypeForReports,	
						cal.PeriodType,
						cal.StartDate,
						cal.EndDate,
						Cardholders = COUNT(DISTINCT iom.CompositeID),
						[Grouping] = @Grouping,
						ReportDate = @Today
				FROM #CalendarIO_VirginPCA cal
				CROSS APPLY (	SELECT	iom.CompositeID
								FROM [WH_VirginPCA].[Derived].[IronOfferMember] iom
								WHERE cal.IronOfferID = iom.IronOfferID
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_VirginAndVisaBarclaycard ch
												WHERE iom.CompositeID = ch.CompositeID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY cal.PartnerID, cal.OfferTypeForReports, 
					cal.PeriodType, cal.StartDate, cal.EndDate


				-- RetailerID	--	Visa Barclaycard
				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	
					RetailerID,	PublisherID, OfferTypeForReports, PeriodType, StartDate, EndDate, Cardholders, [Grouping], ReportDate)
				SELECT	cal.PartnerID
					,	PublisherID = NULL								
					,	cal.OfferTypeForReports	
					,	cal.PeriodType
					,	cal.StartDate
					,	cal.EndDate
					,	Cardholders = COUNT(DISTINCT iom.CompositeID)
					,	[Grouping] = @Grouping
					,	ReportDate = @Today
				FROM #CalendarIO_VisaBarclaycard cal
				CROSS APPLY (	SELECT	iom.CompositeID
								FROM [WH_Visa].[Derived].[IronOfferMember] iom
								WHERE cal.IronOfferID = iom.IronOfferID
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_VirginAndVisaBarclaycard ch
												WHERE iom.CompositeID = ch.CompositeID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY cal.PartnerID, cal.OfferTypeForReports, 
					cal.PeriodType, cal.StartDate, cal.EndDate


				-- RetailerID	--	nFI
				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	
					RetailerID,	PublisherID, OfferTypeForReports, PeriodType, StartDate, EndDate, Cardholders, [Grouping], ReportDate)
				SELECT	cal.PartnerID
					,	PublisherID = NULL								
					,	cal.OfferTypeForReports	
					,	cal.PeriodType
					,	cal.StartDate
					,	cal.EndDate
					,	Cardholders = COUNT(DISTINCT iom.FanID)
					,	[Grouping] = @Grouping
					,	ReportDate = @Today
				FROM #CalendarIO_nFI cal
				CROSS APPLY (	SELECT	iom.FanID
								FROM [nFI].[Relational].[IronOfferMember] iom
								WHERE cal.IronOfferID = iom.IronOfferID
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_nFI ch
												WHERE iom.FanID = ch.FanID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY cal.PartnerID, cal.OfferTypeForReports, 
					cal.PeriodType, cal.StartDate, cal.EndDate


				-- RetailerID	--	AMEX
				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	
					RetailerID,	PublisherID, OfferTypeForReports, PeriodType, StartDate, EndDate, Cardholders, [Grouping], ReportDate)
				SELECT	y.PartnerID
					,	y.PublisherID
					,	y.OfferTypeForReports
					,	y.PeriodType
					,	y.StartDate
					,	y.EndDate
					,	Cardholders = MAX(y.Cardholders)
					,	[Grouping] = @Grouping
					,	ReportDate = @Today
				FROM (	
						-- AMEX Non-Universal
						SELECT
							PartnerID, PublisherID, OfferTypeForReports, StartDate, EndDate, PeriodType,
							SUM(c.ClickCounts) AS Cardholders
						FROM ( -- c	
								SELECT	DISTINCT
										cal.PartnerID
									,	PublisherID = NULL								--	NULL / cal.PublisherID
									,	OfferTypeForReports = cal.OfferTypeForReports	--	NULL / cal.OfferTypeForReports
									,	cal.IronOfferID
									,	cal.StartDate
									,	cal.EndDate
									,	cal.PeriodType
									,	CASE WHEN (o.RetailerID = 4265 AND o.PublisherID = -1) THEN ame.ExposedCounts ELSE ame.ClickCounts END AS ClickCounts
									,	ROW_NUMBER() OVER (PARTITION BY cal.IronOfferID, cal.StartDate, cal.EndDate, cal.PeriodType ORDER BY DATEDIFF(day, ame.ReceivedDate, cal.EndDate) ASC) AS DateRank
								FROM #CalendarIO_AMEX cal
								INNER JOIN [Warehouse].[APW].[AmexExposedClickCounts] ame
									ON cal.IronOfferID = ame.IronOfferID
								INNER JOIN [nFI].[Relational].AmexOffer o
									ON cal.IronOfferID = o.IronOfferID
								WHERE o.SegmentID <> 0
									AND o.SegmentID IS NOT NULL
									AND ame.ClickCounts > 0
						) c
						WHERE DateRank = 1
						GROUP BY PartnerID, PublisherID, OfferTypeForReports, StartDate, EndDate, PeriodType

						UNION ALL

						-- AMEX Universal
						SELECT	z.PartnerID	
							,	PublisherID = NULL						--	NULL / z.PublisherID
							,	z.OfferTypeForReports		--	NULL / z.OfferTypeForReports
							,	z.PeriodType
							,	z.StartDate
							,	z.EndDate
							,	SUM(z.Cardholders) AS Cardholders -- Sum over publishers
						FROM (	SELECT	c.PartnerID	-- AMEX Universal
									,	c.PublisherID
									,	c.OfferTypeForReports
									,	c.PeriodType
									,	c.StartDate
									,	c.EndDate
									,	Cardholders = MAX(c.ClickCounts)
								FROM (	SELECT	DISTINCT
												cal.PartnerID
											,	cal.PublisherID
											,	cal.OfferTypeForReports		--	NULL / o.OfferTypeForReports
											,	cal.IronOfferID
											,	cal.PeriodType
											,	cal.StartDate
											,	cal.EndDate
											,	CASE WHEN (o.RetailerID = 4265 AND o.PublisherID = -1) THEN ame.ExposedCounts ELSE ame.ClickCounts END AS ClickCounts
											,	ROW_NUMBER() OVER (PARTITION BY cal.IronOfferID, cal.StartDate, cal.EndDate, cal.PeriodType ORDER BY DATEDIFF(day, ame.ReceivedDate, cal.EndDate) ASC) AS DateRank
										FROM #CalendarIO_AMEX cal
										INNER JOIN [Warehouse].[APW].[AmexExposedClickCounts] ame
											ON cal.IronOfferID = ame.IronOfferID
											--AND DATEADD(day, 1, ame.ReceivedDate) <= cal.EndDate
										INNER JOIN [nFI].[Relational].[AmexOffer] o
											ON cal.IronOfferID = o.IronOfferID
										WHERE (o.SegmentID = 0 OR o.SegmentID IS NULL) -- Universal AMEX offers
										AND ame.ClickCounts > 0) c
								WHERE c.DateRank = 1
								GROUP BY	c.PartnerID
										,	c.PublisherID
										,	c.OfferTypeForReports
										,	c.StartDate
										,	c.EndDate
										,	c.PeriodType) z
						GROUP BY	z.PartnerID
							--	,	z.PublisherID
								,	z.OfferTypeForReports
								,	z.PeriodType
								,	z.StartDate
								,	z.EndDate) y
				GROUP BY	y.PartnerID
						,	y.PublisherID
						,	y.OfferTypeForReports
						,	y.StartDate
						,	y.EndDate	
						,	y.PeriodType
						,	y.PublisherID
						,	y.OfferTypeForReports


				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_CJM] (	
					RetailerID, PublisherID, OfferTypeForReports, PeriodType, StartDate, EndDate, [Grouping], ReportDate,	
					Cardholders)
				SELECT 
					RetailerID, PublisherID, OfferTypeForReports, PeriodType, StartDate, EndDate, [Grouping], ReportDate,	
					Cardholders = SUM(Cardholders)
				FROM [Staging].[WeeklySummaryV2_CardholderCounts_Interim] 
				GROUP BY 
					RetailerID, PublisherID, OfferTypeForReports, PeriodType, StartDate, EndDate, [Grouping], ReportDate

				

			SET @Msg = 'Iteration [' + CAST(@RowNum AS VARCHAR(10)) + ' complete]'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT

			SET @RowNum = @RowNum + 1;

		END -- End loop over retailers

END


RETURN 0

--SELECT * INTO [Staging].[WeeklySummaryV2_CardholderCounts_CJM] FROM [Staging].[WeeklySummaryV2_CardholderCounts] WHERE 0 = 1
