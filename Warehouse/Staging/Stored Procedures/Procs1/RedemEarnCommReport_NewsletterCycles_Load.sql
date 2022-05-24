/******************************************************************************
Author: Jason Shipp
Created: 20/06/2019
Purpose:
	- Load redemption, communication and online activity metrics split by Book Type and card type for MyRewards active customers, per newsletter sent biweekly cycle
	- Data feeds Redemptions Earnings Communications Report
	- The following tables are updated:
		- Warehouse.Staging.RedemEarnCommReport_ReportData_Redemptions
		- Warehouse.Staging.RedemEarnCommReport_ReportData_OnlineActivity

Notes:
	- Needs same access level as ProcessOp user
	
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE Staging.RedemEarnCommReport_NewsletterCycles_Load
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Declare variables
	******************************************************************************/

	DECLARE @Today date = CAST(GETDATE() AS date);
	DECLARE @AnalysisStartDate date = DATEADD(week, -60, @Today);

	DECLARE @OriginCycleStartDate date = '2018-01-04'; -- Hardcoded random Newsletter Cycle start date

	DECLARE @ReportDateToUse date;

	/******************************************************************************
	Load 2-week cycle date table
	******************************************************************************/

	IF OBJECT_ID('tempdb..#BiweekCalendar') IS NOT NULL DROP TABLE #BiweekCalendar;

	WITH cte AS
		(SELECT @OriginCycleStartDate AS CycleStartDate -- Anchor member
		UNION ALL
		SELECT CAST((DATEADD(week, 2, CycleStartDate)) AS DATE) -- Campaign Cycle start date: recursive member
		FROM   cte
		WHERE DATEADD(DAY, -1, (DATEADD(week, 4, cte.CycleStartDate))) < @Today -- Terminator: last complete cycle end date before the end of the analysis period
		)
	, Staging AS (
		SELECT TOP 26
			'Week' AS PeriodType
			, (cte.CycleStartDate) AS StartDate
			, DATEADD(day, 13, cte.CycleStartDate) AS EndDate
		FROM cte
		WHERE DATEADD(day, 13, cte.CycleStartDate) >= @AnalysisStartDate
		ORDER BY StartDate DESC -- Needed for SELECT TOP
	)
	SELECT 
		ROW_NUMBER() OVER (ORDER BY StartDate) AS ID
		, PeriodType
		, StartDate
		, EndDate
	INTO #BiweekCalendar
	FROM Staging
	OPTION (MAXRECURSION 10000);
	
	CREATE UNIQUE CLUSTERED INDEX UCIX_BiweekCalendar ON #BiweekCalendar (StartDate, EndDate);

	/******************************************************************************
	Load active customers per cycle
	******************************************************************************/

	IF OBJECT_ID('tempdb..#ActiveCustomersList') IS NOT NULL DROP TABLE #ActiveCustomersList;

	SELECT DISTINCT
		d.ID
		, d.StartDate
		, d.EndDate
		, c.FanID
	INTO #ActiveCustomersList
	FROM Warehouse.Relational.Customer c
	INNER JOIN #BiweekCalendar d
		ON (d.EndDate < c.DeactivatedDate OR c.DeactivatedDate IS NULL)
		AND (c.ActivatedDate <= d.EndDate);

	CREATE NONCLUSTERED INDEX nix_Combo ON #ActiveCustomersList (ID) INCLUDE (FanID);

	/******************************************************************************
	Load member book types (front book / back book) and available payment methods per cycle
	******************************************************************************/

	IF OBJECT_ID('tempdb..#BookType') IS NOT NULL DROP TABLE #BookType;

	SELECT
		f.ID AS FanID
		, f.SourceUID
		, ic.ID AS IssuerCustomerID
		, ica.AttributeID
		, ica.StartDate
		, ica.EndDate
		, ica.Value
	INTO #BookType
	FROM SLC_Report.dbo.Fan f
	INNER JOIN SLC_Report.dbo.IssuerCustomer ic
		ON	f.SourceUID = ic.SourceUID
		AND	(
				(f.ClubID = 132 AND ic.IssuerID = 2)
				OR (f.ClubID = 138 AND ic.IssuerID = 1)
			)
	INNER JOIN SLC_Report.dbo.IssuerCustomerAttribute ica
		ON ic.ID = ica.IssuerCustomerID
	INNER JOIN Warehouse.Relational.Customer c
		ON f.ID = c.FanID
	WHERE
		ica.AttributeID = 2; -- Front Book

	CREATE CLUSTERED INDEX cix_FanID ON #BookType (FanID);
	CREATE NONCLUSTERED INDEX nix_FanID_StartDate_EndDate_Value ON #BookType (FanID) INCLUDE (StartDate,EndDate,Value);

	-- Create pseudo end dates to handle cases where back books aren't assigned an end date when front books open

	IF OBJECT_ID('tempdb..#BookType2') IS NOT NULL DROP TABLE #BookType2;

	SELECT
		b.FanID
		, b.SourceUID
		, b.IssuerCustomerID
		, b.AttributeID
		, b.StartDate
		, b.EndDate
		, b.Value
		, CASE
			WHEN EndDate IS NOT NULL THEN EndDate
			WHEN LEAD(StartDate,1,0) OVER (PARTITION BY FanID ORDER BY StartDate) = '1900-01-01' THEN NULL
			ELSE LEAD(StartDate,1,0) OVER (PARTITION BY FanID ORDER BY StartDate) -- Next account start date assigned as account end date
		END AS PseudoEndDate
		INTO #BookType2
		FROM #BookType b;

	CREATE CLUSTERED INDEX cix_FanID ON #BookType2 (FanID);
	CREATE NONCLUSTERED INDEX nix_FanID_StartDate_PseudoEndDate_Value ON #BookType2 (FanID) INCLUDE (StartDate,PseudoEndDate,Value);

	-- Update members who have closed accounts (and transitioned from B -> F but have not been labelled as such)
	
	UPDATE bt SET
	bt.EndDate = DATEADD(SECOND,-1,c.StartDate)
	, bt.PseudoEndDate = DATEADD(SECOND,-1,c.StartDate)
	FROM #BookType2 bt
	INNER JOIN (
			SELECT
			FanID
			, StartDate
			FROM #BookType2 a
			WHERE
				Value = 'F'
				AND	EXISTS (
					SELECT NULL
					FROM #BookType2 b
					WHERE
						Value = 'B'
						AND	a.FanID = b.FanID
						AND a.EndDate = b.EndDate
				)
	) c
		ON bt.FanID = c.FanID
	WHERE
	bt.Value = 'B';

	-- Update members who have closed accounts (and transitioned from B -> F) but have a B close date > F close date)
	
	UPDATE bt SET
	bt.EndDate = DATEADD(SECOND,-1,c.StartDate)
	, bt.PseudoEndDate = DATEADD(SECOND,-1,c.StartDate)
	FROM #BookType2 bt
	INNER JOIN (
			SELECT
			FanID
			, StartDate
			FROM #BookType2 a
			WHERE
				Value = 'F'
				AND	EXISTS (
					SELECT NULL
					FROM #BookType2 b
					WHERE
						Value = 'B'
						AND	a.FanID = b.FanID
						AND a.EndDate < b.EndDate
				)
	) c
		ON bt.FanID = c.FanID
	WHERE
	bt.Value = 'B';

	-- Update B members whose back book had closed off separate to their front book

	UPDATE bt SET	
	bt.EndDate = DATEADD(SECOND,-1,c.StartDate)
	, bt.PseudoEndDate = DATEADD(SECOND,-1,c.StartDate)
	FROM #BookType2 bt
	INNER JOIN (
			SELECT
			FanID
			, StartDate
			FROM #BookType2 a
			WHERE
				Value = 'F'
				AND	EXISTS (
					SELECT NULL
					FROM #BookType2 b
					WHERE
						Value = 'B'
						AND	a.FanID = b.FanID
						AND a.EndDate IS NULL
						AND b.EndDate > a.StartDate
				)
	) c
		ON	bt.FanID = c.FanID
	WHERE 
	bt.Value = 'B';

	-- Load book types per cyle

	IF OBJECT_ID('tempdb..#BookTypeByCycle') IS NOT NULL DROP TABLE #BookTypeByCycle;

	SELECT
		d.ID
		, c.FanID
		, c.Value
	INTO #BookTypeByCycle
	FROM #BookType2	c
	INNER JOIN #BiweekCalendar	d
		ON (d.EndDate < c.PseudoEndDate OR c.PseudoEndDate IS NULL)
		AND (c.StartDate <= d.EndDate);

	CREATE NONCLUSTERED INDEX nix_Combo ON #BookTypeByCycle (ID,FanID) INCLUDE (Value);
	CREATE CLUSTERED INDEX cix_ID ON #BookTypeByCycle (ID);

	-- Load payment methods per cycle

	IF OBJECT_ID('tempdb..#CustomerPaymentMethods') IS NOT NULL DROP TABLE #CustomerPaymentMethods;

	SELECT
		d.ID
		, c.FanID
		, c.PaymentMethodsAvailableID
	INTO #CustomerPaymentMethods
	FROM Warehouse.Relational.CustomerPaymentMethodsAvailable c
	INNER JOIN #BiweekCalendar d
		ON	c.StartDate <= d.EndDate
		AND	(c.EndDate IS NULL OR d.EndDate < c.EndDate);

	CREATE NONCLUSTERED INDEX nix_Combo ON #CustomerPaymentMethods (ID,FanID) INCLUDE (PaymentMethodsAvailableID);
	CREATE CLUSTERED INDEX cix_ID ON #CustomerPaymentMethods (ID);

	-- Merge cycle results

	IF OBJECT_ID('tempdb..#SchemeMembershipLabels') IS NOT NULL DROP TABLE #SchemeMembershipLabels;

	SELECT
		a.ID
		, a.FanID
		, COALESCE(bc.Value,'B') AS Value
		, cp.PaymentMethodsAvailableID
		, CASE
			WHEN cp.PaymentMethodsAvailableID IN (0,2) THEN 1
			ELSE 0
		END AS DebitFlag
		, CASE
			WHEN cp.PaymentMethodsAvailableID IN (1,2) THEN 1
			ELSE 0
		END AS CreditFlag
		, CASE
			WHEN PaymentMethodsAvailableID = 0 THEN 'Debit Only'
			WHEN PaymentMethodsAvailableID = 1 THEN 'Credit Only'
			WHEN PaymentMethodsAvailableID = 2 THEN 'Debit and Credit'
			ELSE 'None'
		END AS PaymentCardMethod
	INTO #SchemeMembershipLabels
	FROM #ActiveCustomersList a
	LEFT JOIN #BookTypeByCycle bc
		ON a.ID = bc.ID
		AND a.FanID = bc.FanID
	LEFT JOIN #CustomerPaymentMethods cp 
		ON a.ID = cp.ID
		AND	a.FanID = cp.FanID;

	CREATE NONCLUSTERED INDEX nix_Combo ON #SchemeMembershipLabels (ID) INCLUDE (FanID);

	-- Merge summary results

	IF OBJECT_ID('tempdb..#SummarySchemeMembershipLabels') IS NOT NULL DROP TABLE #SummarySchemeMembershipLabels;

	SELECT	
		d.ID
		, sml.FanID
	INTO #SummarySchemeMembershipLabels
	FROM #BiweekCalendar d
	INNER JOIN	#SchemeMembershipLabels sml
		ON d.ID = sml.ID
	WHERE
		NOT (Value = 'B' AND PaymentCardMethod = 'Debit Only')
		AND PaymentCardMethod != 'None'

	CREATE NONCLUSTERED INDEX nix_Combo ON #SummarySchemeMembershipLabels (ID) INCLUDE (FanID);

	/******************************************************************************
	Load redemptions
	******************************************************************************/

	-- Load redemptions per cycle

	IF OBJECT_ID('tempdb..#Redemptions') IS NOT NULL DROP TABLE #Redemptions;

	SELECT
		d.ID
		, 3 AS IsSummary
		, r.FanID
		, COUNT(*) AS Redemptions
	INTO #Redemptions
	FROM Warehouse.Relational.Redemptions r
	INNER JOIN #BiweekCalendar d
		ON d.StartDate <= r.RedeemDate
		AND r.RedeemDate <= d.EndDate
	INNER JOIN #SummarySchemeMembershipLabels a
		ON d.ID = a.ID
		AND r.FanID = a.FanID
	GROUP BY
		d.ID
		, r.FanID;

	CREATE NONCLUSTERED INDEX cix_ComboID ON #Redemptions (ID) INCLUDE (FanID);

	/******************************************************************************
	Load book type and redemption data
	******************************************************************************/

	-- Load active members by book type and payment method per cycle

	IF OBJECT_ID('tempdb..#ToplineActiveByBookType') IS NOT NULL DROP TABLE #ToplineActiveByBookType;

	SELECT
		smt.ID
		, 3 AS IsSummary
		, NULL AS Value
		, NULL AS PaymentMethodsAvailableID
		, NULL AS DebitFlag
		, NULL AS CreditFlag
		, NULL AS PaymentCardMethod
		, COUNT(smt.FanID) AS ActiveCustomers
	INTO #ToplineActiveByBookType
	FROM #SummarySchemeMembershipLabels smt
	GROUP BY
		smt.ID;

	-- Load active member redemptions by book type and payment method

	IF OBJECT_ID('tempdb..#CycleRedemptionsActiveByBookType') IS NOT NULL DROP TABLE #CycleRedemptionsActiveByBookType;

	SELECT
		r.ID
		, r.IsSummary
		, NULL AS Value
		, NULL AS PaymentMethodsAvailableID
		, NULL AS DebitFlag
		, NULL AS CreditFlag
		, NULL AS PaymentCardMethod		
		, CASE
			WHEN r.Redemptions = 1 THEN '1'
			WHEN r.Redemptions = 2 THEN '2'
			WHEN r.Redemptions = 3 THEN '3'
			WHEN r.Redemptions = 4 THEN '4'
			ELSE '5'
		END AS RedemptionsCount
		, COUNT(r.FanID) AS RedeemersCount
	INTO #CycleRedemptionsActiveByBookType
	FROM #Redemptions r
	WHERE
		r.IsSummary = 3
	GROUP BY 
		r.ID
		, r.IsSummary
		, CASE
			WHEN r.Redemptions = 1 THEN '1'
			WHEN r.Redemptions = 2 THEN '2'
			WHEN r.Redemptions = 3 THEN '3'
			WHEN r.Redemptions = 4 THEN '4'
			ELSE '5'
		END;

	/******************************************************************************
	Load redemption report data
	******************************************************************************/

	IF @Today > (SELECT MAX(ReportDate) FROM Warehouse.Staging.RedemEarnCommReport_ReportData_Redemptions)
		SET @ReportDateToUse = (SELECT MAX(ReportDate) FROM Warehouse.Staging.RedemEarnCommReport_ReportData_Redemptions)
	ELSE
		SET @ReportDateToUse = @Today;

	INSERT INTO Warehouse.Staging.RedemEarnCommReport_ReportData_Redemptions (
		PeriodID
		, RollingMonthStart
		, RollingMonthEnd
		, BookTypeValue
		, PaymentMethodsAvailableID
		, DebitFlag
		, CreditFlag
		, PaymentCardMethod
		, RedemptionsCount
		, ActiveCustomers
		, RedeemersCount12M
		, YTDRedeemersCount
		, IsSummary
		, ReportDate
	)
	SELECT 
		d.ID AS PeriodID
		, d.StartDate
		, d.EndDate
		, b.Value AS BookTypeValue
		, b.PaymentMethodsAvailableID
		, b.DebitFlag
		, b.CreditFlag
		, b.PaymentCardMethod
		, b.RedemptionsCount
		, a.ActiveCustomers
		, b.RedeemersCount AS RedeemersCount12M
		, NULL AS YTDRedeemersCount
		, 3 AS IsSummary
		, @ReportDateToUse AS ReportDate
	FROM #BiweekCalendar d
	INNER JOIN #ToplineActiveByBookType a
		ON a.IsSummary = 3
		AND d.ID = a.ID
	LEFT JOIN #CycleRedemptionsActiveByBookType b
		ON b.IsSummary = 3
		AND a.ID = b.ID
		AND (a.Value IS NULL AND b.Value IS NULL)
		AND	(a.PaymentMethodsAvailableID IS NULL AND b.PaymentMethodsAvailableID IS NULL)
		AND	(a.DebitFlag IS NULL AND b.DebitFlag IS NULL)
		AND	(a.CreditFlag IS NULL AND b.CreditFlag IS NULL)
		AND	(a.PaymentCardMethod IS NULL AND b.PaymentCardMethod IS NULL)
	WHERE NOT EXISTS (
		SELECT NULL FROM Warehouse.Staging.RedemEarnCommReport_ReportData_Redemptions x
		WHERE 
			@ReportDateToUse = x.ReportDate
			AND d.ID = x.PeriodID
			AND d.StartDate = x.RollingMonthStart
			AND d.EndDate = x.RollingMonthEnd
			AND (b.Value IS NULL AND x.BookTypeValue IS NULL)
			AND (b.PaymentMethodsAvailableID IS NULL AND x.PaymentMethodsAvailableID IS NULL)
			AND (b.DebitFlag IS NULL AND x.DebitFlag IS NULL)
			AND (b.CreditFlag IS NULL AND x.CreditFlag IS NULL)
			AND (b.PaymentCardMethod IS NULL AND x.PaymentCardMethod IS NULL)
			AND b.RedemptionsCount = x.RedemptionsCount
			AND x.IsSummary = 3
	)
	OPTION (RECOMPILE);

	/******************************************************************************
	Load communications and online activity data
	******************************************************************************/
	
	-- Load email marketable flag per cycle

	IF OBJECT_ID('tempdb..#SummaryMarketableFlag') IS NOT NULL DROP TABLE #SummaryMarketableFlag;

	SELECT DISTINCT
		d.ID
		, mkt.FanID
		, mkt.MarketableByEmail
	INTO #SummaryMarketableFlag
	FROM Warehouse.Relational.Customer_MarketableByEmailStatus mkt
	INNER JOIN #BiweekCalendar d
		ON	mkt.StartDate <= d.EndDate
		AND	(mkt.EndDate IS NULL OR d.EndDate < mkt.EndDate)
	INNER JOIN #SummarySchemeMembershipLabels a
		ON d.ID = a.ID
		AND mkt.FanID = a.FanID
	WHERE
		mkt.MarketableByEmail = 1
	GROUP BY
		d.ID
		, mkt.FanID
		, mkt.MarketableByEmail;

	CREATE NONCLUSTERED INDEX nix_ComboID ON #SummaryMarketableFlag (ID,FanID) INCLUDE (MarketableByEmail);

	-- Load registered members per cycle

	IF OBJECT_ID('tempdb..#SummaryRegisteredCustomersList') IS NOT NULL DROP TABLE #SummaryRegisteredCustomersList;

	SELECT DISTINCT
		d.ID
		, c.FanID
		, c.Registered
	INTO #SummaryRegisteredCustomersList
	FROM Warehouse.Relational.Customer_Registered c
	INNER JOIN #BiweekCalendar d
		ON c.StartDate <= d.EndDate
		AND	(c.EndDate IS NULL OR d.EndDate < c.EndDate)
	INNER JOIN #SummarySchemeMembershipLabels a
		ON d.ID = a.ID
		AND c.FanID = a.FanID
	WHERE
		c.Registered = 1;

	CREATE NONCLUSTERED INDEX nix_Combo ON #SummaryRegisteredCustomersList (ID) INCLUDE (FanID);

	-- Load email opens per cycle

	IF OBJECT_ID('tempdb..#EmailOpens') IS NOT NULL DROP TABLE #EmailOpens;

	SELECT 
		d.ID
		, 3 AS IsSummary
		, ee.FanID 
		, COUNT(DISTINCT ee.CampaignKey) AS EmailOpens
	INTO #EmailOpens
	FROM Warehouse.Relational.EmailEvent ee -- List of Events
	INNER JOIN #BiweekCalendar d
		ON d.StartDate <= ee.EventDate
		AND ee.EventDate <= d.EndDate
	INNER JOIN (
			SELECT DISTINCT
			CampaignKey
			FROM Warehouse.Relational.EmailCampaign
			WHERE 
				CampaignName LIKE '%NEWSLETTER%'
				AND CampaignName NOT LIKE '%COPY%' 
				AND CampaignName NOT LIKE '%TEST%'
	) cls -- List of newsletter emails
		ON	ee.CampaignKey = cls.CampaignKey
	INNER JOIN #SummarySchemeMembershipLabels a
		ON d.ID = a.ID
		AND ee.FanID = a.FanID
	WHERE 
		ee.EmailEventCodeID IN (
			1301 -- Email open
			,605  -- Link click
		)
	GROUP BY 
		d.ID
		, ee.FanID;

	CREATE NONCLUSTERED INDEX nix_Combo ON #EmailOpens (ID) INCLUDE (FanID);
	CREATE NONCLUSTERED INDEX nix_Combo2 ON #EmailOpens (IsSummary) INCLUDE (ID,FanID);

	-- Load web logins per cycle

	IF OBJECT_ID('tempdb..#WebLogins') IS NOT NULL DROP TABLE #WebLogins;
	
	SELECT
		d.ID
		, wl.FanID
		, COUNT(DISTINCT CAST(TrackDate AS DATE)) AS WebLogins
	INTO #WebLogins
	FROM Warehouse.Relational.WebLogins wl
	INNER JOIN #BiweekCalendar d
		ON d.StartDate <= wl.TrackDate
		AND wl.TrackDate <= d.EndDate
	INNER JOIN #SummarySchemeMembershipLabels a
		ON d.ID = a.ID
		AND wl.FanID = a.FanID
	INNER JOIN #SummaryRegisteredCustomersList c
		ON d.ID = c.ID
		AND	wl.FanID = c.FanID
	GROUP BY 
		d.ID
		, wl.FanID;

	CREATE NONCLUSTERED INDEX nix_Combo ON #WebLogins (ID) INCLUDE (FanID);

	/******************************************************************************
	Load online activity report data
	******************************************************************************/

	IF @Today > (SELECT MAX(ReportDate) FROM Warehouse.Staging.RedemEarnCommReport_ReportData_OnlineActivity)
		SET @ReportDateToUse = (SELECT MAX(ReportDate) FROM Warehouse.Staging.RedemEarnCommReport_ReportData_OnlineActivity)
	ELSE
		SET @ReportDateToUse = @Today;

	INSERT INTO Warehouse.Staging.RedemEarnCommReport_ReportData_OnlineActivity (
		PeriodID
		, YYYYMM
		, MonthStart
		, MonthEnd
		, BookTypeValue
		, PaymentCardMethod
		, MarketableByEmail
		, Registered
		, ActiveCustomers
		, EmailOpeners
		, WebsiteLogins_3M
		, WebsiteLogins_12M
		, IsSummary
		, ReportDate
	)	
	SELECT
		d.ID AS PeriodID
		, LEFT(CONVERT(VARCHAR, d.EndDate,112),6) AS YYYYMM
		, d.StartDate
		, d.EndDate
		, NULL AS BookTypeValue
		, NULL AS PaymentCardMethod
		, COALESCE(mf.MarketableByEmail,0) AS MarketableByEmail
		, COALESCE(rc.Registered,0) AS Registered
		, COUNT(c.FanID) AS ActiveCustomers
		, COUNT(eo.FanID) AS EmailOpeners
		, COUNT(wl1.FanID) AS WebsiteLogins_3M
		, COUNT(wl1.FanID) AS WebsiteLogins_12M
		, 3 AS IsSummary
		, @ReportDateToUse AS ReportDate
	FROM #SummarySchemeMembershipLabels c
	INNER JOIN #BiweekCalendar d
		ON c.ID = d.ID
	LEFT JOIN #SummaryMarketableFlag mf
		ON d.ID = mf.ID
		AND c.FanID = mf.FanID
	LEFT JOIN #SummaryRegisteredCustomersList rc
		ON d.ID = rc.ID
		AND c.FanID = rc.FanID
	LEFT JOIN #EmailOpens eo
		ON eo.IsSummary = 3
		AND c.ID = eo.ID
		AND	c.FanID = eo.FanID
	LEFT JOIN #WebLogins wl1
		ON c.ID = wl1.ID
		AND	c.FanID = wl1.FanID
	WHERE NOT EXISTS (
		SELECT NULL FROM Warehouse.Staging.RedemEarnCommReport_ReportData_OnlineActivity x
		WHERE 
			@ReportDateToUse = x.ReportDate
			AND d.ID = x.PeriodID
			AND d.StartDate = x.MonthStart
			AND d.EndDate = x.MonthEnd
			AND x.BookTypeValue IS NULL
			AND x.PaymentCardMethod IS NULL
			AND (COALESCE(mf.MarketableByEmail,0) = x.MarketableByEmail)
			AND (COALESCE(rc.Registered,0) = x.Registered)
			AND x.IsSummary = 3
	)
	GROUP BY
		d.ID
		, LEFT(CONVERT(VARCHAR, d.EndDate,112),6)
		, d.StartDate
		, d.EndDate
		, COALESCE(mf.MarketableByEmail,0)
		, COALESCE(rc.Registered,0)
	OPTION (RECOMPILE);

END