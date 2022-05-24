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
CREATE PROCEDURE [Staging].[WeeklySummaryV2_LoadCardholderCounts]
AS
BEGIN
	
	SET NOCOUNT ON;

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

		-- Virgin PCA customers

			INSERT INTO #Customer (FanID, CompositeID, PublisherID, ActivationDate, DeactivationDate)	

			SELECT	cu.FanID
				,	cu.CompositeID
				,	cu.ClubID AS PublisherID
				,	cu.RegistrationDate AS ActivationDate
				,	cu.DeactivatedDate AS DeactivationDate
			FROM [WH_VirginPCA].[Derived].[Customer] cu;

		-- Visa customers

			INSERT INTO #Customer (FanID, CompositeID, PublisherID, ActivationDate, DeactivationDate)	

			SELECT	cu.FanID
				,	cu.CompositeID
				,	cu.ClubID AS PublisherID
				,	cu.RegistrationDate AS ActivationDate
				,	cu.DeactivatedDate AS DeactivationDate
			FROM [WH_Visa].[Derived].[Customer] cu;

		CREATE CLUSTERED INDEX cx_Stuff ON #Customer (CompositeID);
		CREATE NONCLUSTERED INDEX ix_Stuff ON #Customer (ActivationDate ASC, DeactivationDate ASC) INCLUDE (FanID);	

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

			INSERT INTO #CardHolderStaging	--	Virgin
			SELECT	DISTINCT
					c.FanID
				,	c.CompositeID
				,	c.PublisherID
				,	ISNULL(c.ActivationDate, '1900-01-01') AS CardCustStartDate
				,	ISNULL(c.DeactivationDate, '9999-12-31') AS CardCustEndDate
			FROM #Customer c
			WHERE c.PublisherID = 166;

			INSERT INTO #CardHolderStaging	--	Virgin PCA
			SELECT	DISTINCT
					c.FanID
				,	c.CompositeID
				,	c.PublisherID
				,	ISNULL(c.ActivationDate, '1900-01-01') AS CardCustStartDate
				,	ISNULL(c.DeactivationDate, '9999-12-31') AS CardCustEndDate
			FROM #Customer c
			WHERE c.PublisherID = 182;

			INSERT INTO #CardHolderStaging	--	Visa Barclaycard
			SELECT	DISTINCT
					c.FanID
				,	c.CompositeID
				,	c.PublisherID
				,	ISNULL(c.ActivationDate, '1900-01-01') AS CardCustStartDate
				,	ISNULL(c.DeactivationDate, '9999-12-31') AS CardCustEndDate
			FROM #Customer c
			WHERE c.PublisherID = 180;

			CREATE CLUSTERED INDEX cx_Stuff ON #CardHolderStaging (CompositeID, CardCustStartDate, CardCustEndDate);

			DELETE
			FROM #CardHolderStaging
			WHERE CardCustStartDate > CardCustEndDate;

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

			CREATE CLUSTERED INDEX CIX_CompDates ON #CardHolder_Warehouse (CompositeID, CardCustStartDate, CardCustEndDate);

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

			CREATE CLUSTERED INDEX CIX_CompDates ON #CardHolder_VirginAndVisaBarclaycard (CompositeID, CardCustStartDate, CardCustEndDate);

			IF OBJECT_ID ('tempdb..#CardHolder_nFI') IS NOT NULL DROP TABLE #CardHolder_nFI;
			SELECT	FanID
				,	CompositeID
				,	CardCustStartDate = MIN(ts)
				,	CardCustEndDate = MAX(ts)
			INTO #CardHolder_nFI
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
											WHERE m.PublisherID NOT IN (132, 138, 166, 180, 182)) c 
									) d
							) e 
					WHERE e.RangeEnd = 0
					OR e.RangeStart = 0) f
			GROUP BY	FanID
					,	CompositeID
					,	RowPair;

			CREATE CLUSTERED INDEX CIX_CompDates ON #CardHolder_nFI (FanID, CardCustStartDate, CardCustEndDate);

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

		IF OBJECT_ID ('tempdb..#Dates') IS NOT NULL DROP TABLE #Dates;
		SELECT	cs.StartDate
			,	cs.EndDate
			,	ROW_NUMBER() OVER (ORDER BY cs.StartDate, cs.EndDate) AS RowNum
		INTO #Dates
		FROM (	SELECT	DISTINCT
						StartDate
					,	EndDate
				FROM #CalendarIOSetup) cs

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

		WHILE @RowNum <= @MaxRowNum

		BEGIN
			/*****************************
			Prepare calendar table for individual partner
			*****************************/
		
				SELECT	@StartDate = StartDate
					,	@EndDate = EndDate
				--	,	@PartnerID = PartnerID
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
				AND s.EndDate = @EndDate
			--	AND s.PartnerID = @PartnerID
				;

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
				AND s.EndDate = @EndDate
			--	AND s.PartnerID = @PartnerID
				;
				;

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
				AND s.EndDate = @EndDate
			--	AND s.PartnerID = @PartnerID
				;

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
				AND s.EndDate = @EndDate
			--	AND s.PartnerID = @PartnerID
				;

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
				AND s.EndDate = @EndDate
			--	AND s.PartnerID = @PartnerID
				;

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
				AND s.EndDate = @EndDate
			--	AND s.PartnerID = @PartnerID
				;

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

				DECLARE	@Grouping VARCHAR(25)
					,	@Today DATE = GETDATE()

				SET @Grouping = 'Retailer'

				TRUNCATE TABLE [Staging].[WeeklySummaryV2_CardholderCounts_Interim]

				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	RetailerID	--	Warehouse
																				,	PublisherID
																				,	OfferTypeForReports
																				,	PeriodType
																				,	StartDate
																				,	EndDate
																				,	Cardholders
																				,	[Grouping]
																				,	ReportDate)
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
							--	AND @StartDate <= iom.StartDate
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_Warehouse ch
												WHERE iom.CompositeID = ch.CompositeID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY	cal.PartnerID
					--	,	cal.PublisherID
					--	,	cal.OfferTypeForReports
						,	cal.StartDate
						,	cal.EndDate
						,	cal.PeriodType

				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	RetailerID	--	Virgin
																				,	PublisherID
																				,	OfferTypeForReports
																				,	PeriodType
																				,	StartDate
																				,	EndDate
																				,	Cardholders
																				,	[Grouping]
																				,	ReportDate)
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
							--	AND @StartDate <= iom.StartDate
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_VirginAndVisaBarclaycard ch
												WHERE iom.CompositeID = ch.CompositeID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY	cal.PartnerID
					--	,	cal.PublisherID
					--	,	cal.OfferTypeForReports
						,	cal.StartDate
						,	cal.EndDate
						,	cal.PeriodType

				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	RetailerID	--	Virgin PCA
																				,	PublisherID
																				,	OfferTypeForReports
																				,	PeriodType
																				,	StartDate
																				,	EndDate
																				,	Cardholders
																				,	[Grouping]
																				,	ReportDate)
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
							--	AND @StartDate <= iom.StartDate
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_VirginAndVisaBarclaycard ch
												WHERE iom.CompositeID = ch.CompositeID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY	cal.PartnerID
					--	,	cal.PublisherID
					--	,	cal.OfferTypeForReports
						,	cal.StartDate
						,	cal.EndDate
						,	cal.PeriodType

				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	RetailerID	--	Visa Barclaycard
																				,	PublisherID
																				,	OfferTypeForReports
																				,	PeriodType
																				,	StartDate
																				,	EndDate
																				,	Cardholders
																				,	[Grouping]
																				,	ReportDate)
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
							--	AND @StartDate <= iom.StartDate
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_VirginAndVisaBarclaycard ch
												WHERE iom.CompositeID = ch.CompositeID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY	cal.PartnerID
					--	,	cal.PublisherID
					--	,	cal.OfferTypeForReports
						,	cal.StartDate
						,	cal.EndDate
						,	cal.PeriodType

				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	RetailerID	--	nFI
																				,	PublisherID
																				,	OfferTypeForReports
																				,	PeriodType
																				,	StartDate
																				,	EndDate
																				,	Cardholders
																				,	[Grouping]
																				,	ReportDate)
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
							--	AND @StartDate <= iom.StartDate
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_nFI ch
												WHERE iom.FanID = ch.FanID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY	cal.PartnerID
					--	,	cal.PublisherID
					--	,	cal.OfferTypeForReports
						,	cal.StartDate
						,	cal.EndDate
						,	cal.PeriodType

				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	RetailerID	--	AMEX
																				,	PublisherID
																				,	OfferTypeForReports
																				,	PeriodType
																				,	StartDate
																				,	EndDate
																				,	Cardholders
																				,	[Grouping]
																				,	ReportDate)
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

				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts] (	RetailerID
																		,	PublisherID
																		,	OfferTypeForReports
																		,	PeriodType
																		,	StartDate
																		,	EndDate
																		,	Cardholders
																		,	[Grouping]
																		,	ReportDate)
				SELECT	cci.RetailerID
					,	cci.PublisherID
					,	cci.OfferTypeForReports
					,	cci.PeriodType
					,	cci.StartDate
					,	cci.EndDate		
					,	Cardholders = SUM(cci.Cardholders)
					,	cci.[Grouping]
					,	cci.ReportDate
				FROM [Staging].[WeeklySummaryV2_CardholderCounts_Interim] cci
				GROUP BY	cci.RetailerID
						,	cci.StartDate
						,	cci.EndDate	
						,	cci.PeriodType
						,	cci.PublisherID
						,	cci.OfferTypeForReports			
						,	cci.[Grouping]
						,	cci.ReportDate;

			/*****************************
			Grouped by publisher
			*****************************/

				SET @Grouping = 'RetailerPublisher'

				TRUNCATE TABLE [Staging].[WeeklySummaryV2_CardholderCounts_Interim]

				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	RetailerID	--	Warehouse
																				,	PublisherID
																				,	OfferTypeForReports
																				,	PeriodType
																				,	StartDate
																				,	EndDate
																				,	Cardholders
																				,	[Grouping]
																				,	ReportDate)
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
							--	AND @StartDate <= iom.StartDate
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_Warehouse ch
												WHERE iom.CompositeID = ch.CompositeID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY	cal.PartnerID
						,	cal.PublisherID
					--	,	cal.OfferTypeForReports
						,	cal.StartDate
						,	cal.EndDate
						,	cal.PeriodType

				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	RetailerID	--	Virgin
																				,	PublisherID
																				,	OfferTypeForReports
																				,	PeriodType
																				,	StartDate
																				,	EndDate
																				,	Cardholders
																				,	[Grouping]
																				,	ReportDate)
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
							--	AND @StartDate <= iom.StartDate
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_VirginAndVisaBarclaycard ch
												WHERE iom.CompositeID = ch.CompositeID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY	cal.PartnerID
						,	cal.PublisherID
					--	,	cal.OfferTypeForReports
						,	cal.StartDate
						,	cal.EndDate
						,	cal.PeriodType

				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	RetailerID	--	Virgin PCA
																				,	PublisherID
																				,	OfferTypeForReports
																				,	PeriodType
																				,	StartDate
																				,	EndDate
																				,	Cardholders
																				,	[Grouping]
																				,	ReportDate)
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
							--	AND @StartDate <= iom.StartDate
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_VirginAndVisaBarclaycard ch
												WHERE iom.CompositeID = ch.CompositeID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY	cal.PartnerID
						,	cal.PublisherID
					--	,	cal.OfferTypeForReports
						,	cal.StartDate
						,	cal.EndDate
						,	cal.PeriodType

				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	RetailerID	--	Visa Barclaycard
																				,	PublisherID
																				,	OfferTypeForReports
																				,	PeriodType
																				,	StartDate
																				,	EndDate
																				,	Cardholders
																				,	[Grouping]
																				,	ReportDate)
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
							--	AND @StartDate <= iom.StartDate
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_VirginAndVisaBarclaycard ch
												WHERE iom.CompositeID = ch.CompositeID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY	cal.PartnerID
						,	cal.PublisherID
					--	,	cal.OfferTypeForReports
						,	cal.StartDate
						,	cal.EndDate
						,	cal.PeriodType

				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	RetailerID	--	nFI
																				,	PublisherID
																				,	OfferTypeForReports
																				,	PeriodType
																				,	StartDate
																				,	EndDate
																				,	Cardholders
																				,	[Grouping]
																				,	ReportDate)
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
							--	AND @StartDate <= iom.StartDate
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_nFI ch
												WHERE iom.FanID = ch.FanID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY	cal.PartnerID
						,	cal.PublisherID
					--	,	cal.OfferTypeForReports
						,	cal.StartDate
						,	cal.EndDate
						,	cal.PeriodType

				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	RetailerID	--	AMEX
																				,	PublisherID
																				,	OfferTypeForReports
																				,	PeriodType
																				,	StartDate
																				,	EndDate
																				,	Cardholders
																				,	[Grouping]
																				,	ReportDate)
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
				GROUP BY	y.PartnerID
						,	y.PublisherID
						,	y.OfferTypeForReports
						,	y.StartDate
						,	y.EndDate	
						,	y.PeriodType
						,	y.PublisherID
						,	y.OfferTypeForReports

				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts] (	RetailerID
																		,	PublisherID
																		,	OfferTypeForReports
																		,	PeriodType
																		,	StartDate
																		,	EndDate
																		,	Cardholders
																		,	[Grouping]
																		,	ReportDate)
				SELECT	cci.RetailerID
					,	cci.PublisherID
					,	cci.OfferTypeForReports
					,	cci.PeriodType
					,	cci.StartDate
					,	cci.EndDate		
					,	Cardholders = SUM(cci.Cardholders)
					,	cci.[Grouping]
					,	cci.ReportDate
				FROM [Staging].[WeeklySummaryV2_CardholderCounts_Interim] cci
				GROUP BY	cci.RetailerID
						,	cci.StartDate
						,	cci.EndDate	
						,	cci.PeriodType
						,	cci.PublisherID
						,	cci.OfferTypeForReports			
						,	cci.[Grouping]
						,	cci.ReportDate;

			/*****************************
			Grouped by segment
			*****************************/

				SET @Grouping = 'RetailerOfferType'

				TRUNCATE TABLE [Staging].[WeeklySummaryV2_CardholderCounts_Interim]

				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	RetailerID	--	Warehouse
																				,	PublisherID
																				,	OfferTypeForReports
																				,	PeriodType
																				,	StartDate
																				,	EndDate
																				,	Cardholders
																				,	[Grouping]
																				,	ReportDate)
				SELECT	PartnerID = cal.PartnerID
					,	PublisherID = NULL								--	NULL / cal.PublisherID
					,	OfferTypeForReports = cal.OfferTypeForReports	--	NULL / cal.OfferTypeForReports
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
							--	AND @StartDate <= iom.StartDate
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_Warehouse ch
												WHERE iom.CompositeID = ch.CompositeID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY	cal.PartnerID
					--	,	cal.PublisherID
						,	cal.OfferTypeForReports
						,	cal.StartDate
						,	cal.EndDate
						,	cal.PeriodType

				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	RetailerID	--	Virgin
																				,	PublisherID
																				,	OfferTypeForReports
																				,	PeriodType
																				,	StartDate
																				,	EndDate
																				,	Cardholders
																				,	[Grouping]
																				,	ReportDate)
				SELECT	PartnerID = cal.PartnerID
					,	PublisherID = NULL								--	NULL / cal.PublisherID
					,	OfferTypeForReports = cal.OfferTypeForReports	--	NULL / cal.OfferTypeForReports
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
							--	AND @StartDate <= iom.StartDate
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_VirginAndVisaBarclaycard ch
												WHERE iom.CompositeID = ch.CompositeID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY	cal.PartnerID
					--	,	cal.PublisherID
						,	cal.OfferTypeForReports
						,	cal.StartDate
						,	cal.EndDate
						,	cal.PeriodType

				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	RetailerID	--	Virgin PCA
																				,	PublisherID
																				,	OfferTypeForReports
																				,	PeriodType
																				,	StartDate
																				,	EndDate
																				,	Cardholders
																				,	[Grouping]
																				,	ReportDate)
				SELECT	PartnerID = cal.PartnerID
					,	PublisherID = NULL								--	NULL / cal.PublisherID
					,	OfferTypeForReports = cal.OfferTypeForReports	--	NULL / cal.OfferTypeForReports
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
							--	AND @StartDate <= iom.StartDate
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_VirginAndVisaBarclaycard ch
												WHERE iom.CompositeID = ch.CompositeID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY	cal.PartnerID
					--	,	cal.PublisherID
						,	cal.OfferTypeForReports
						,	cal.StartDate
						,	cal.EndDate
						,	cal.PeriodType

				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	RetailerID	--	Visa Barclaycard
																				,	PublisherID
																				,	OfferTypeForReports
																				,	PeriodType
																				,	StartDate
																				,	EndDate
																				,	Cardholders
																				,	[Grouping]
																				,	ReportDate)
				SELECT	PartnerID = cal.PartnerID
					,	PublisherID = NULL								--	NULL / cal.PublisherID
					,	OfferTypeForReports = cal.OfferTypeForReports	--	NULL / cal.OfferTypeForReports
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
							--	AND @StartDate <= iom.StartDate
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_VirginAndVisaBarclaycard ch
												WHERE iom.CompositeID = ch.CompositeID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY	cal.PartnerID
					--	,	cal.PublisherID
						,	cal.OfferTypeForReports
						,	cal.StartDate
						,	cal.EndDate
						,	cal.PeriodType

				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	RetailerID	--	nFI
																				,	PublisherID
																				,	OfferTypeForReports
																				,	PeriodType
																				,	StartDate
																				,	EndDate
																				,	Cardholders
																				,	[Grouping]
																				,	ReportDate)
				SELECT	PartnerID = cal.PartnerID
					,	PublisherID = NULL								--	NULL / cal.PublisherID
					,	OfferTypeForReports = cal.OfferTypeForReports	--	NULL / cal.OfferTypeForReports
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
							--	AND @StartDate <= iom.StartDate
								AND iom.StartDate <= cal.EndDate
								AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
								AND EXISTS (	SELECT 1
												FROM #CardHolder_nFI ch
												WHERE iom.FanID = ch.FanID
												AND ch.CardCustStartDate <= cal.EndDate
												AND ch.CardCustEndDate >= cal.StartDate)) iom
				GROUP BY	cal.PartnerID
					--	,	cal.PublisherID
						,	cal.OfferTypeForReports
						,	cal.StartDate
						,	cal.EndDate
						,	cal.PeriodType

				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts_Interim] (	RetailerID	--	AMEX
																				,	PublisherID
																				,	OfferTypeForReports
																				,	PeriodType
																				,	StartDate
																				,	EndDate
																				,	Cardholders
																				,	[Grouping]
																				,	ReportDate)
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
							,	PublisherID = NULL						--	NULL / z.PublisherID
							,	OfferTypeForReports = z.OfferTypeForReports		--	NULL / z.OfferTypeForReports
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
											,	PublisherID = cal.PublisherID
											,	OfferTypeForReports = cal.OfferTypeForReports		--	NULL / o.OfferTypeForReports
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

				INSERT INTO [Staging].[WeeklySummaryV2_CardholderCounts] (	RetailerID
																		,	PublisherID
																		,	OfferTypeForReports
																		,	PeriodType
																		,	StartDate
																		,	EndDate
																		,	Cardholders
																		,	[Grouping]
																		,	ReportDate)
				SELECT	cci.RetailerID
					,	cci.PublisherID
					,	cci.OfferTypeForReports
					,	cci.PeriodType
					,	cci.StartDate
					,	cci.EndDate		
					,	Cardholders = SUM(cci.Cardholders)
					,	cci.[Grouping]
					,	cci.ReportDate
				FROM [Staging].[WeeklySummaryV2_CardholderCounts_Interim] cci
				GROUP BY	cci.RetailerID
						,	cci.StartDate
						,	cci.EndDate	
						,	cci.PeriodType
						,	cci.PublisherID
						,	cci.OfferTypeForReports			
						,	cci.[Grouping]
						,	cci.ReportDate

				OPTION(RECOMPILE);

			SET @RowNum = @RowNum + 1;

		END -- End loop over retailers

END
