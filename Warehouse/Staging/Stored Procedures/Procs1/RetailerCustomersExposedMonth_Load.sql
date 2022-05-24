/******************************************************************************
Author: Jason Shipp
Created: 14/02/2019
Purpose: 
	- Loads new cardholder counts per retailer for the most recent calendar month into Warehouse.Staging.RetailerCustomersExposedMonth
	- Loads new base cardholder counts for the most recent calendar month into Staging.RetailerCustomerBaseMonth

------------------------------------------------------------------------------
Modification History

Jason Shipp 04/04/2019
	- Revised AMEX logic to account for multiple PublisherIDs

08/07/2019 Jason Shipp
	- Added commented out logic to ensure cardholder dates overlap Iron Offer membership dates in the analysis periods
	- This lowers query performance, so there is no need to implement this unless this extra business logic is required

12/08/2019 Jason Shipp
	- Ignored AMEX-type ClickCounts of 0
	- Added delete of cases where the CardCustStartDate > CardCustEndDate in the #CardHolder table

07/01/2020 Jason Shipp
    - Amended Waitrose AMEX logic to fetch exposed members instead of members who clicked

******************************************************************************/
CREATE PROCEDURE [Staging].[RetailerCustomersExposedMonth_Load]
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @Today DATE = CAST(GETDATE() AS DATE);
	DECLARE @LastMonthStart date = (SELECT DATEADD(month, -1, DATEADD(day, -(DATEPART(d, @Today)-1), @Today)));
	DECLARE @LastMonthEnd date = (SELECT EOMONTH(@LastMonthStart));

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

	IF OBJECT_ID ('tempdb..#CardHolder') IS NOT NULL DROP TABLE #CardHolder;

	SELECT DISTINCT
		c.FanID
		, c.CompositeID
		, c.PublisherID
		, CAST(CASE WHEN pc.AdditionDate > c.ActivationDate THEN pc.AdditionDate ELSE c.ActivationDate END AS date) AS CardCustStartDate
		, CAST(CASE WHEN (pc.RemovalDate < c.DeactivationDate OR c.DeactivationDate IS NULL) THEN pc.RemovalDate ELSE c.DeactivationDate END AS date) AS CardCustEndDate
	INTO #CardHolder
	FROM #Customer c
	INNER JOIN SLC_Report.dbo.Pan pc
		ON c.CompositeID = pc.CompositeID;

	CREATE NONCLUSTERED INDEX ix_Stuff ON #CardHolder (CompositeID) INCLUDE (CardCustStartDate, CardCustEndDate);
	CREATE NONCLUSTERED INDEX ix_Stuff2 ON #CardHolder (FanID) INCLUDE (CardCustStartDate, CardCustEndDate);

	DELETE FROM #CardHolder
	WHERE CardCustStartDate > CardCustEndDate;

	/******************************************************************************
	Load calendar-IronOffer details table
	******************************************************************************/

	IF OBJECT_ID ('tempdb..#CalendarIOSetup') IS NOT NULL DROP TABLE #CalendarIOSetup;

	SELECT -- Warehouse
		@LastMonthStart AS StartDate
		, @LastMonthEnd AS EndDate
		, 'Month' AS PeriodType
		, o.IronOfferID
		, COALESCE(pa.AlternatePartnerID, o.PartnerID) AS PartnerID
		, 'Warehouse' AS PublisherType
	INTO #CalendarIOSetup
	FROM Warehouse.Relational.IronOffer o
	LEFT JOIN #PartnerAlternate pa
		ON o.PartnerID = pa.PartnerID
	WHERE
		o.IssignedOff = 1
		AND o.IronOfferName NOT LIKE 'Spare%' -- Exclude spare offers
		AND o.StartDate <= @LastMonthEnd
		AND (o.EndDate IS NULL OR o.EndDate >= @LastMonthStart)

	UNION ALL

	SELECT -- nFI
		@LastMonthStart AS StartDate
		, @LastMonthEnd AS EndDate
		, 'Month' AS PeriodType
		, o.ID AS IronOfferID
		, COALESCE(pa.AlternatePartnerID, o.PartnerID) AS PartnerID
		, 'nFI' AS PublisherType
	FROM nFI.Relational.IronOffer o
	LEFT JOIN #PartnerAlternate pa
		ON o.PartnerID = pa.PartnerID
	WHERE
		o.IssignedOff = 1
		AND o.IronOfferName NOT LIKE 'Spare%' -- Exclude spare offers
		AND o.StartDate <= @LastMonthEnd
		AND (o.EndDate IS NULL OR o.EndDate >= @LastMonthStart)
	
	UNION ALL

	SELECT -- AMEX
		@LastMonthStart AS StartDate
		, @LastMonthEnd AS EndDate
		, 'Month' AS PeriodType
		, o.IronOfferID
		, COALESCE(pa.AlternatePartnerID, o.RetailerID) AS PartnerID
		, 'AMEX' AS PublisherType
	FROM nFI.Relational.AmexOffer o
	LEFT JOIN #PartnerAlternate pa
		ON o.RetailerID = pa.PartnerID
	WHERE
		o.StartDate <= @LastMonthEnd
		AND (o.EndDate IS NULL OR o.EndDate >= @LastMonthStart)
	
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
		SELECT DISTINCT PartnerID
		FROM #CalendarIOSetup
	) x
	WHERE NOT EXISTS (
		SELECT NULL FROM Warehouse.Staging.RetailerCustomersExposedMonth m -- Check entry for retailer doesn't already exist in results table
		WHERE 
		@LastMonthStart = m.MonthDate
		AND x.PartnerID = m.RetailerID
	);

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

	WHILE @RowNum <= @MaxRowNum

	BEGIN
		
		SET @PartnerID = (SELECT PartnerID FROM #Retailers WHERE RowNum = @RowNum);

		IF OBJECT_ID ('tempdb..#CalendarIO') IS NOT NULL DROP TABLE #CalendarIO;

		SELECT
			s.StartDate
			, s.EndDate
			, s.PeriodType
			, s.IronOfferID
			, s.PublisherType
			, s.PartnerID
		INTO #CalendarIO
		FROM #CalendarIOSetup s
		WHERE s.PartnerID = @PartnerID;

		CREATE CLUSTERED INDEX CIX_CalendarIO ON #CalendarIO (IronOfferID, StartDate, EndDate);

		/******************************************************************************
		Load rows into cardholder counts table

		-- Create table for storing results

		CREATE TABLE Warehouse.Staging.RetailerCustomersExposedMonth (
			ID int IDENTITY(1,1) NOT NULL
			, RetailerID int NOT NULL
			, MonthDate date NOT NULL
			, CustomerCount int NOT NULL
			CONSTRAINT [PK_Staging_RetailerCustomersExposedMonth] PRIMARY KEY CLUSTERED (ID ASC)
		);

		ALTER TABLE Staging.RetailerCustomersExposedMonth
		ADD CONSTRAINT UC_RetailerCustomersExposedMonth UNIQUE (RetailerID, MonthDate);
		******************************************************************************/

		INSERT INTO Staging.RetailerCustomersExposedMonth (
			RetailerID
			, MonthDate
			, CustomerCount
		)
		SELECT
			x.PartnerID
			, x.StartDate
			, SUM(x.Cardholders) AS Cardholders
		FROM (
			SELECT -- Warehouse
				cal.PartnerID
				, cal.StartDate
				, cal.EndDate
				, COUNT(DISTINCT(iom.CompositeID)) AS Cardholders
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
				--AND EXISTS (
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
		
			UNION ALL

			SELECT -- nFI
				cal.PartnerID
				, cal.StartDate
				, cal.EndDate
				, COUNT(DISTINCT(iom.FanID)) AS Cardholders
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
				--AND EXISTS (
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
				, cal.StartDate
				, cal.EndDate

			UNION ALL

			SELECT -- Max AMEX cardholders (=clicks) (Non-Universal or Universal)
				y.PartnerID
				, y.StartDate
				, y.EndDate			
				, MAX(y.Cardholders) AS Cardholders
			FROM (
				SELECT -- AMEX Non-Universal
					c.PartnerID
					, c.StartDate
					, c.EndDate
					, SUM(c.ClickCounts) AS Cardholders
				FROM (
					SELECT DISTINCT
						cal.PartnerID
						, cal.IronOfferID
						, cal.StartDate
						, cal.EndDate
						, CASE WHEN (o.RetailerID = 4265 AND o.PublisherID = -1) THEN ame.ExposedCounts ELSE ame.ClickCounts END AS ClickCounts
						, ROW_NUMBER() OVER (PARTITION BY cal.IronOfferID, cal.StartDate, cal.EndDate, cal.PeriodType ORDER BY DATEDIFF(day, ame.ReceivedDate, cal.EndDate) ASC) AS DateRank
					FROM #CalendarIO cal
					INNER JOIN Warehouse.APW.AmexExposedClickCounts ame
						ON cal.IronOfferID = ame.IronOfferID
						AND DATEADD(day, 1, ame.ReceivedDate) <= cal.EndDate
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
				UNION ALL
				SELECT -- AMEX Universal
					z.PartnerID
					, z.StartDate
					, z.EndDate
					, SUM(z.Cardholders) AS Cardholders -- Sum over publishers
				FROM (
					SELECT
						c.PublisherID
						, c.PartnerID
						, c.StartDate
						, c.EndDate
						, MAX(c.ClickCounts) AS Cardholders -- Max per partner-publisher
					FROM (
						SELECT DISTINCT
							o.PublisherID
							, cal.PartnerID
							, cal.IronOfferID
							, cal.StartDate
							, cal.EndDate
							, CASE WHEN (o.RetailerID = 4265 AND o.PublisherID = -1) THEN ame.ExposedCounts ELSE ame.ClickCounts END AS ClickCounts
							, ROW_NUMBER() OVER (PARTITION BY cal.IronOfferID, cal.StartDate, cal.EndDate, cal.PeriodType ORDER BY DATEDIFF(day, ame.ReceivedDate, cal.EndDate) ASC) AS DateRank
						FROM #CalendarIO cal
						INNER JOIN Warehouse.APW.AmexExposedClickCounts ame
							ON cal.IronOfferID = ame.IronOfferID
							AND DATEADD(day, 1, ame.ReceivedDate) <= cal.EndDate
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
				) z
				GROUP BY
					z.PartnerID
					, z.StartDate
					, z.EndDate

			) y
			GROUP BY 
				y.PartnerID
				, y.StartDate
				, y.EndDate	
		) x
		GROUP BY
			x.PartnerID
			, x.StartDate
		OPTION(RECOMPILE);

		SET @RowNum = @RowNum + 1;

	END -- End loop over retailers

	/******************************************************************************
	Load cardholder universe count into base cardholder counts table

	-- Create table for storing results

	CREATE TABLE Warehouse.Staging.RetailerCustomerBaseMonth (
		MonthDate date NOT NULL
		, CustomerBase int NOT NULL
		, CONSTRAINT PK_Staging_RetailerCustomerBaseMonth PRIMARY KEY CLUSTERED (MonthDate ASC)
	);
	******************************************************************************/

	DELETE FROM Warehouse.Staging.RetailerCustomerBaseMonth WHERE MonthDate = @LastMonthStart;

	INSERT INTO Warehouse.Staging.RetailerCustomerBaseMonth (
		MonthDate
		, CustomerBase
	)
	SELECT
		x.StartDate
		, SUM(x.Cardholders) AS Cardholders
	FROM (
		SELECT -- Warehouse
			cal.StartDate
			, cal.EndDate
			, COUNT(DISTINCT(iom.CompositeID)) AS Cardholders
		FROM #CalendarIOSetup cal
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
			--AND EXISTS (
			--	SELECT NULL FROM #CardHolder ch
			--	WHERE 
			--	(ch.CardCustStartDate <= CAST(iom.EndDate AS date) OR iom.EndDate IS NULL)
			--	AND (ch.CardCustEndDate >= CAST(iom.StartDate AS date) OR ch.CardCustEndDate IS NULL)
			--)
			AND (iom.StartDate <= cal.EndDate OR iom.StartDate IS NULL)
			AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
			AND cal.PublisherType = 'Warehouse'
		GROUP BY
			cal.StartDate
			, cal.EndDate
		
		UNION ALL

		SELECT -- nFI
			cal.StartDate
			, cal.EndDate
			, COUNT(DISTINCT(iom.FanID)) AS Cardholders
		FROM #CalendarIOSetup cal
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
			--AND EXISTS (
			--	SELECT NULL FROM #CardHolder ch
			--	WHERE 
			--	(ch.CardCustStartDate <= CAST(iom.EndDate AS date) OR iom.EndDate IS NULL)
			--	AND (ch.CardCustEndDate >= CAST(iom.StartDate AS date) OR ch.CardCustEndDate IS NULL)
			--)
			AND (iom.StartDate <= cal.EndDate OR iom.StartDate IS NULL)
			AND (iom.EndDate >= cal.StartDate OR iom.EndDate IS NULL)
			AND cal.PublisherType = 'nFI'
		GROUP BY
			cal.StartDate
			, cal.EndDate

		UNION ALL

		SELECT -- AMEX
			y.StartDate
			, y.EndDate
			, SUM(y.Cardholders) AS Cardholders -- Sum over publishers
		FROM (
			SELECT 
				cal.StartDate
				, cal.EndDate
				, o.PublisherID
				, MAX(ame.ExposedCounts) AS Cardholders -- Max per publisher
			FROM #CalendarIOSetup cal
			INNER JOIN Warehouse.APW.AmexExposedClickCounts ame
				ON cal.IronOfferID = ame.IronOfferID
			INNER JOIN nFI.Relational.AmexOffer o
				ON cal.IronOfferID = o.IronOfferID
			WHERE
				ame.ReceivedDate BETWEEN @LastMonthStart AND @LastMonthEnd
				AND ame.ExposedCounts >0
			GROUP BY
				cal.StartDate
				, cal.EndDate
				, o.PublisherID
		) y
		GROUP BY
			y.StartDate
			, y.EndDate

	) x
	GROUP BY
		x.StartDate;
	
END