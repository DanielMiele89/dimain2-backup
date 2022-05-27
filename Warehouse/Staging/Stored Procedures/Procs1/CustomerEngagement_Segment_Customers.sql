/******************************************************************************
Author: Jason Shipp
Created: 17/05/2018
Purpose: 
	- Assigns engagement segments to My Rewards customers according to their online behaviour for customers active in an x-month period
	- Customers and their segmented inserted into Warehouse.Staging.CustomerEngagement_Customer_Segment table
	- The segmentation part of the query will occur if y-months have elapsed since the last segmentation
	- Segments used for grouping results for the Customer Engagement report
	
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE Staging.CustomerEngagement_Segment_Customers
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/**************************************************************************
	Fetch segmentation period dates
	***************************************************************************/

	-- Declare variables for calendar
	
	DECLARE @Today DATE = CAST(GETDATE() AS DATE);
	DECLARE @OriginEndDate DATE = '2017-12-31'; -- Hard coded (start date for first segmentation)
	DECLARE @SegmentationPeriodLengthMonths INT = 6;
	DECLARE @SegmentationFrequencyLengthMonths INT = 6;

	-- Initialise calendar table

	IF OBJECT_ID('tempdb..#Calendar') IS NOT NULL DROP TABLE #Calendar;

	CREATE TABLE #Calendar
		(StartDate DATE NOT NULL
		, EndDate DATE NOT NULL
		);

	-- Use CTE to fetch dates of most recent complete ?-month block to segment customers over

	WITH cte AS
		(SELECT @OriginEndDate AS EndDate -- Anchor member: hard coded
		UNION ALL
		SELECT EOMONTH(
			(DATEADD(MONTH, (@SegmentationFrequencyLengthMonths-1)
				, (DATEADD(DAY, 1, EndDate))
			)) 
		) -- Recursive member: end of month @SegmentationFrequencyLengthMonths months later
		FROM   cte
		WHERE
			EOMONTH(
				(DATEADD(MONTH, (@SegmentationFrequencyLengthMonths-1)
					, (DATEADD(DAY, 1, EndDate))
				)) 
			) < @Today -- Terminator: period ending before today
		)
	INSERT INTO #Calendar
		(StartDate
		, EndDate
		)
	SELECT
		MAX(
			DATEADD(month, -(@SegmentationPeriodLengthMonths-1)
				, (DATEADD(DAY, -((DATEPART(DAY, cte.EndDate))-1), cte.EndDate))
			)
		) AS StartDate -- Define start of segmentation period: beginning of month @SegmentationPeriodLengthMonths before EndDate 
		, MAX(cte.EndDate) AS EndDate
	FROM cte
	OPTION (MAXRECURSION 1000);

	DECLARE @StartDate DATE = (SELECT StartDate FROM #Calendar)
	DECLARE @EndDate DATE = (SELECT EndDate FROM #Calendar)

	/**************************************************************************
	Segment customers (if enough time has passed since the last segmentation)
	***************************************************************************/

	IF @StartDate > (SELECT MAX(SegmentStartDate) FROM Warehouse.Staging.CustomerEngagement_Customer_Segment) -- Check segmentation dates are new
	BEGIN

		-- Get customers who were active in the period

		IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers;

		SELECT
			c.FanID
			, MAX(CAST(mas.MarketableByEmail AS int)) AS MarketableByEmail
		INTO #Customers
		FROM Warehouse.Relational.customer c
		INNER JOIN Warehouse.MI.CustomerActivationPeriod cap
			ON cap.FanID = c.FanID
		INNER JOIN Warehouse.Relational.Customer_MarketableByEmailStatus mas
			ON mas.FanID = c.FanID
		WHERE NOT EXISTS (
				SELECT NULL
				FROM Warehouse.Staging.Customer_DuplicateSourceUID dup
				WHERE
					EndDate IS NULL
					AND c.SourceUID = dup.SourceUID
				)
		AND cap.ActivationStart <= @StartDate
		AND (cap.ActivationEnd IS NULL OR cap.ActivationEnd > @EndDate)
		AND mas.StartDate <= @EndDate
		AND (mas.EndDate IS NULL OR mas.EndDate > @EndDate)
		GROUP BY
			c.FanID;

		CREATE CLUSTERED INDEX INX ON #Customers(FanID);

		-- Get weblogins

		IF OBJECT_ID('tempdb..#Weblogins') IS NOT NULL DROP TABLE #Weblogins;

		SELECT
			wl.FanID
			, COUNT(DISTINCT CAST(trackdate AS date)) as weblogins
		Into #Weblogins
		From warehouse.relational.WebLogins wl
		INNER JOIN #Customers c
			on c.FanID = wl.fanid
		WHERE 
			wl.trackdate BETWEEN @StartDate AND @EndDate
		GROUP BY
			wl.FanID;

		-- Get email opens

		IF OBJECT_ID('tempdb..#EmailOpens') IS NOT NULL DROP TABLE #EmailOpens;

		SELECT 
			ee.FanID
			, COUNT(DISTINCT ec.CampaignKey) AS EmailOpens
		INTO #EmailOpens
		FROM Warehouse.Relational.CampaignLionSendIDs cls -- List of campaign emails
		INNER JOIN Warehouse.Relational.EmailEvent ee -- list of events
			ON cls.CampaignKey = ee.CampaignKey
		INNER JOIN #Customers c
			ON c.FanID = ee.fanid
		INNER JOIN (SELECT CampaignKey, CampaignName FROM Warehouse.Relational.EmailCampaign WHERE CampaignName LIKE '%Newsletter%') ec
			on ec.CampaignKey = ee.CampaignKey
		WHERE 
			ee.EmailEventCodeID in (
				1301 -- Email Open
				, 605 -- Link Click
			) 
			AND ee.EventDate BETWEEN @StartDate AND @EndDate
		GROUP BY 
			ee.FanID;

		-- Calculate a score

		IF OBJECT_ID('tempdb..#Scoring') IS NOT NULL DROP TABLE #Scoring;

		SELECT 
			c.fanid
			, c.Marketablebyemail
			, CASE WHEN w.fanid IS NULL THEN 0 ELSE 2 * w.weblogins END + CASE WHEN eo.fanid IS NULL THEN 0 ELSE eo.EmailOpens END AS Score
			, CASE WHEN w.fanid IS NULL THEN 0 ELSE w.weblogins END AS WLs_ForSegmentation
			, CASE WHEN eo.fanid IS NULL THEN 0 ELSE eo.EmailOpens END AS EOs_ForSegmentation
		INTO #Scoring
		FROM #Customers c
		LEFT JOIN #Weblogins w
			ON w.fanid = c.fanid
		LEFT JOIN #EmailOpens eo
			ON eo.FanID = c.FanID;

		IF OBJECT_ID('tempdb..#EngagementBlock') IS NOT NULL DROP TABLE #EngagementBlock;

		SELECT
			FanID
			, Score
			, NTILE(5) OVER (ORDER BY Score DESC) AS InteractionTile
			, WLs_ForSegmentation
			, EOs_ForSegmentation
		INTO #EngagementBlock
		FROM #Scoring
		WHERE
			Score <> 0;

		-- Categorise customers

		IF OBJECT_ID('tempdb..#SegmentationTable') IS NOT NULL DROP TABLE #SegmentationTable;

		SELECT 
			s.FanID
			, s.Marketablebyemail
			, s.Score
			, s.WLs_ForSegmentation
			, s.EOs_ForSegmentation
			, CASE 
				WHEN eb.fanid IS NULL AND MarketableByEmail = 0 THEN 'Non-Engaged'
				WHEN eb.fanid IS NULL AND MarketableByEmail = 1 THEN 'Low-Engaged'
				WHEN eb.fanid IS NOT NULL THEN CAST(InteractionTile AS varchar(30))
				ELSE 'Error' 
			END AS EngagementSegment
		INTO #SegmentationTable
		FROM #Scoring s
		LEFT JOIN #EngagementBlock eb
			ON eb.fanid = s.FanID;

		-- Get payment methods

		IF OBJECT_ID('tempdb..#PaymentMethods') IS NOT NULL DROP TABLE #PaymentMethods;

		SELECT DISTINCT
			t.FanID
			, pa.[Description]
		INTO #PaymentMethods
		FROM Warehouse.Relational.CustomerPaymentMethodsAvailable t
		INNER JOIN Warehouse.relational.PaymentMethodsAvailable pa
			 ON t.PaymentMethodsAvailableID = pa.PaymentMethodsAvailableID
		WHERE
			StartDate <= @EndDate
			AND (EndDate IS NULL OR EndDate > @EndDate);

		/**************************************************************************
		Load customers and their engagement segments

		-- Create table for storing results:

		CREATE TABLE Warehouse.Staging.CustomerEngagement_Customer_Segment (
			ID int IDENTITY(1,1)
			, SegmentStartDate date
			, SegmentEndDate date
			, FanID int NOT NULL
			, Marketablebyemail int NULL
			, Score int NULL
			, WLs_ForSegmentation int NULL
			, EOs_ForSegmentation int NULL
			, EngagementSegment varchar(30) NULL
			, DebitCard int NOT NULL
			, CreditCard int NOT NULL
			, BothDebitAndCreditCard int NOT NULL
			, CONSTRAINT PK_CustomerEngagement_Customer_Segment PRIMARY KEY CLUSTERED (ID)
		); 

		CREATE NONCLUSTERED INDEX IX_CustomerEngagement_Customer_Segment ON Staging.CustomerEngagement_Customer_Segment (
			SegmentStartDate, SegmentEndDate, EngagementSegment) INCLUDE (FanID);
		***************************************************************************/

		INSERT INTO Warehouse.Staging.CustomerEngagement_Customer_Segment (
			SegmentStartDate
			, SegmentEndDate
			, FanID
			, Marketablebyemail
			, Score
			, WLs_ForSegmentation
			, EOs_ForSegmentation
			, EngagementSegment
			, DebitCard
			, CreditCard
			, BothDebitAndCreditCard
		)
		SELECT
			@StartDate
			, @EndDate
			, st.FanID
			, st.Marketablebyemail
			, st.Score
			, st.WLs_ForSegmentation
			, st.EOs_ForSegmentation
			, st.EngagementSegment
			, CASE WHEN pma.[Description] = 'Debit Card' THEN 1 ELSE 0 END AS DebitCard
			, CASE WHEN pma.[Description] = 'Credit Card' THEN 1 ELSE 0 END AS CreditCard
			, CASE WHEN pma.[Description] = 'Both' THEN 1 ELSE 0 END AS BothDebitAndCreditCard
		FROM #SegmentationTable st
		LEFT JOIN (SELECT FanID, [Description] FROM #PaymentMethods) pma 
			ON pma.FanID = st.FanID
		WHERE NOT EXISTS (
			SELECT NULL FROM Staging.CustomerEngagement_Customer_Segment x
			WHERE
				@StartDate = x.SegmentStartDate
				AND @EndDate = x.SegmentEndDate
				AND st.EngagementSegment = x.EngagementSegment
			);
	END

END