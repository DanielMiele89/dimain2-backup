/******************************************************************************
Author: Jason Shipp
Created: 17/05/2018
Purpose:
- Calculates card, spend, online behaviour and earnings metrics for the most recent complete calendar month, for My Rewards customers grouped by their level of engagement
- Data inserted into Warehouse.Staging.CustomerEngagement_ReportData
- If 6 months of data already exists in the results table for the latest segmentation dates, no new data is fetched
	
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE Staging.CustomerEngagement_Load_Metrics
	
AS
BEGIN
	
	SET NOCOUNT ON;

	-- Set @MaxSegmentDate so only most recently-segmented customers are analysed 
	
	DECLARE @MaxSegmentDate DATE = (SELECT MAX(SegmentStartDate) FROM Warehouse.Staging.CustomerEngagement_Customer_Segment)

	-- Create calendar table

	DECLARE @Today DATE = CAST(GETDATE() AS DATE);
	DECLARE @EndDate DATE = DATEADD(day, -(DATEPART(DAY, @Today)), @Today) -- End of last complete calendar month
	DECLARE @StartDate DATE = DATEADD(day, -((DATEPART(DAY, @EndDate))-1), @EndDate) -- Start of last complete calendar month

	-- Check if 6 months' worth of data exists in the results table since the current segmentation

	IF (SELECT COUNT(DISTINCT(MonthCommencing)) FROM Warehouse.Staging.CustomerEngagement_ReportData WHERE SegmentStartDate = @MaxSegmentDate) <6
	AND @StartDate > (SELECT MAX(MonthCommencing) FROM Warehouse.Staging.CustomerEngagement_ReportData) -- Check month hasn't already been calculated

	BEGIN

		-- Get weblogins

		IF OBJECT_ID('tempdb..#Weblogins') IS NOT NULL DROP TABLE #Weblogins;

		SELECT 
			wl.FanID
			, COUNT(DISTINCT CAST(wl.Trackdate AS date)) AS weblogins
		INTO #Weblogins
		FROM Warehouse.Relational.WebLogins wl
		INNER JOIN Warehouse.Staging.CustomerEngagement_Customer_Segment c 
			ON wl.fanid = c.FanID
		WHERE
			c.SegmentStartDate = @MaxSegmentDate
			AND wl.trackdate BETWEEN @StartDate AND @EndDate
		GROUP BY 
			wl.FanID;

		-- Get Email Opens

		IF OBJECT_ID('tempdb..#EmailOpens') IS NOT NULL DROP TABLE #EmailOpens;

		SELECT 
			ee.FanID
			, COUNT(DISTINCT ec.CampaignKey) AS EmailOpens
		INTO #EmailOpens
		FROM Warehouse.Relational.CampaignLionSendIDs cls -- List of campaign emails
		INNER JOIN Warehouse.Relational.EmailEvent ee -- list of events
			ON cls.CampaignKey = ee.CampaignKey
		INNER JOIN Warehouse.Staging.CustomerEngagement_Customer_Segment c 
			ON ee.FanID = c.FanID
		INNER JOIN (SELECT CampaignKey FROM Warehouse.Relational.EmailCampaign WHERE CampaignName LIKE '%Newsletter%') ec
			ON ee.CampaignKey = ec.CampaignKey
		WHERE 
			c.SegmentStartDate = @MaxSegmentDate
			AND ee.EmailEventCodeID IN (
				1301 -- Email Open
				, 605 -- Link Click
			) 
			AND ee.EventDate BETWEEN @StartDate AND @EndDate
		GROUP BY 
			ee.FanID;

		-- Earnings and sales on MF offers

		IF OBJECT_ID('tempdb..#MFearnings') IS NOT NULL DROP TABLE #MFearnings;

		SELECT 
			pt.FanID
			, SUM(pt.CashbackEarned) AS CBearned
			, SUM(TransactionAmount) AS Sales
		INTO #MFearnings
		FROM Warehouse.Relational.PartnerTrans pt 
		INNER JOIN Warehouse.Staging.CustomerEngagement_Customer_Segment c
			ON pt.fanid = c.FanID
		WHERE
			c.SegmentStartDate = @MaxSegmentDate
			AND pt.TransactionDate BETWEEN @StartDate AND @EndDate
		GROUP BY 
			pt.FanID;

		-- Earnings and sales on RBS offers

		IF OBJECT_ID('tempdb..#RBSearnings') IS NOT NULL DROP TABLE #RBSearnings;

		SELECT
			pt.fanid
			, CASE WHEN pt.AdditionalCashbackAwardtypeID IN (25,8,10) THEN 'DD' ELSE 'CC' END AS [Type]
			, SUM (CashbackEarned) AS CBearned
			, SUM(Amount) AS Sales
		INTO #RBSearnings
		FROM Warehouse.Relational.AdditionalCashbackAward pt
		INNER JOIN Warehouse.Staging.CustomerEngagement_Customer_Segment c 
			ON pt.fanid = c.FanID
		WHERE
			c.SegmentStartDate = @MaxSegmentDate
			AND pt.TranDate BETWEEN @StartDate AND @EndDate
		GROUP BY 
			pt.FanID
			, CASE WHEN pt.AdditionalCashbackAwardTypeID IN (25,8,10) THEN 'DD' ELSE 'CC' END;

		-- Redemptions

		IF OBJECT_ID('tempdb..#Redemptions') IS NOT NULL DROP TABLE #Redemptions;

		SELECT 
			r.FanID
			, MAX(CASE WHEN r.RedeemType = 'Trade up' THEN 1 ELSE 0 END) AS TradeUpRedeemer
		INTO #Redemptions
		FROM Warehouse.Relational.Redemptions r
		WHERE
			r.RedeemType IN ('Trade up', 'Cash')
			AND r.Redeemdate BETWEEN @StartDate AND @EndDate
		GROUP BY
			r.FanID;

		-- PaymentMethods

		IF OBJECT_ID('tempdb..#PaymentMethods') IS NOT NULL DROP TABLE #PaymentMethods;

		SELECT DISTINCT
			t.FanID
			, pa.[Description]
		INTO #PaymentMethods
		FROM Warehouse.Relational.CustomerPaymentMethodsAvailable t
		INNER JOIN Warehouse.Relational.PaymentMethodsAvailable pa 
			ON t .PaymentMethodsAvailableID = pa.PaymentMethodsAvailableID
		INNER JOIN Warehouse.Staging.CustomerEngagement_Customer_Segment les
			ON t.FanID = les.fanid
		WHERE
			les.SegmentStartDate = @MaxSegmentDate
			AND t.StartDate <= @StartDate
			AND (t.EndDate IS NULL OR t.EndDate > @StartDate);

		-- Get overall counts

		IF OBJECT_ID('tempdb..#Counts') IS NOT NULL DROP TABLE #Counts;

		SELECT 
			COUNT(1) AS [Count]
			, EngagementSegment
		INTO #Counts
		FROM Warehouse.Staging.CustomerEngagement_Customer_Segment cus
		WHERE
			cus.SegmentStartDate = @MaxSegmentDate		
		GROUP BY
			EngagementSegment;

		-- Pre-output table

		IF OBJECT_ID('tempdb..#PreOutput') IS NOT NULL DROP TABLE #PreOutput;

		SELECT 
			cus.EngagementSegment
			, SUM(CASE WHEN pm.[Description] = 'Debit Card' THEN 1 ELSE 0 END) AS NoDebitOnly
			, SUM(CASE WHEN pm.[Description] = 'Credit Card' THEN 1 ELSE 0 END) AS NoCreditOnly
			, SUM(CASE WHEN pm.[Description] = 'Both' THEN 1 ELSE 0 END) AS NoDebitCredit

			, COUNT(1) as Customers

			, SUM(CASE WHEN wl.FanID IS NOT NULL THEN 1 ELSE 0 END) AS LoggedInAtAll
			, SUM(CASE WHEN eo.FanID IS NOT NULL THEN 1 ELSE 0 END) AS OpenedEmailInAtAll

			, SUM(wl.weblogins) AS WebLogins
			, SUM(eo.EmailOpens) AS EmailOpens

			, SUM(CASE WHEN mf.FanID IS NOT NULL THEN 1 ELSE 0 END) AS NoEarnedOnMFs
			, SUM(mf.Sales) AS MFsales

			, SUM(CASE WHEN rbsDD.FanID IS NOT NULL THEN 1 ELSE 0 END) AS NoEarnedOnDDs
			, SUM(rbsDD.CBearned) AS DDearnings
			, SUM(rbsCC.CBearned) AS CCearnings
			, SUM(mf.CBearned) AS MFearnings

			, SUM(CASE WHEN r.FanID IS NOT NULL THEN 1 else 0 end) AS RedeemedAtAll
			, SUM(CASE WHEN r.FanID IS NOT NULL AND r.TradeUpRedeemer = 1 THEN 1 ELSE 0 END) AS TURedeemedAtAll
		INTO #PreOutput
		FROM Warehouse.Staging.CustomerEngagement_Customer_Segment cus
		LEFT JOIN #Weblogins wl 
			ON cus.fanid = wl.fanid
		LEFT JOIN #EmailOpens eo 
			ON cus.fanid = eo.fanid
		LEFT JOIN #MFearnings mf 
			ON cus.fanid = mf.FanID
		LEFT JOIN (SELECT Fanid, CBearned, Sales FROM #RBSearnings WHERE [Type] = 'DD') rbsDD
			ON cus.fanid = rbsDD.FanID
		LEFT JOIN (SELECT Fanid, CBearned, Sales FROM #RBSearnings WHERE [Type] = 'CC') rbsCC
			ON cus.fanid = rbsCC.FanID
		LEFT JOIN #Redemptions r 
			ON cus.fanid = r.FanID
		INNER JOIN #Counts c 
			ON cus.EngagementSegment = c.EngagementSegment
		INNER JOIN #PaymentMethods pm 
			ON cus.fanid = pm.fanid
		GROUP BY 
			cus.EngagementSegment;

		-- Insert report data 

		/******************************************************************************
		-- Create table for storing results:		

		CREATE TABLE Warehouse.Staging.CustomerEngagement_ReportData (
			ID int IDENTITY (1, 1)
			, SegmentStartDate DATE
			, SegmentEndDate DATE
			, EngagementSegment varchar(30)
			, MonthCommencing date		
			, PercentDebitOnly float
			, PercentCreditOnly float
			, PercentDebitCredit float		
			, PercentLoggedIn float
			, PercentOpenedEmail float
			, WLsPerCus float
			, EOsPerCus float
			, PercentEarnedOnDDs float
			, PercentEarnedOnMFs float		
			, SPC_MFoffers float		
			, DDearningsPerCus float
			, CCearningsPerCus float
			, MFearningsPerCus float
			, TotalEarningsPerCus float
			, CONSTRAINT PK_CustomerEngagement_ReportData PRIMARY KEY CLUSTERED (ID)
		)
		******************************************************************************/

		INSERT INTO Warehouse.Staging.CustomerEngagement_ReportData (
			SegmentStartDate
			, SegmentEndDate
			, EngagementSegment
			, MonthCommencing	
			, PercentDebitOnly
			, PercentCreditOnly
			, PercentDebitCredit	
			, PercentLoggedIn
			, PercentOpenedEmail
			, WLsPerCus
			, EOsPerCus
			, PercentEarnedOnDDs
			, PercentEarnedOnMFs		
			, SPC_MFoffers	
			, DDearningsPerCus
			, CCearningsPerCus
			, MFearningsPerCus
			, TotalEarningsPerCus
		)		
		SELECT 
			@MaxSegmentDate AS SegmentStartDate
			, (SELECT MAX(SegmentEndDate) FROM Warehouse.Staging.CustomerEngagement_Customer_Segment WHERE SegmentStartDate = @MaxSegmentDate) AS SegmentEndDate
			, po.EngagementSegment
			, @StartDate AS MonthCommencing
		
			, CAST(NoDebitOnly AS float) / Customers AS PercentDebitOnly
			, CAST(NoCreditOnly AS float) / Customers AS PercentCreditOnly
			, CAST(NoDebitCredit AS float) / Customers AS PercentDebitCredit
		
			, CAST(LoggedInAtAll AS float) / Customers AS PercentLoggedIn
			, CAST(OpenedEmailInAtAll AS float) / Customers AS PercentOpenedEmail
			, CAST(WebLogins AS float) / Customers AS WLsPerCus
			, CAST(EmailOpens AS float) / Customers AS EOsPerCus
			, CAST(NoEarnedOnDDs AS float) / Customers AS PercentEarnedOnDDs
			, CAST(NoEarnedOnMFs AS float) / Customers AS PercentEarnedOnMFs
		
			, CAST(MFsales AS float) / Customers AS SPC_MFoffers
		
			, CAST(DDearnings AS float) / Customers AS DDearningsPerCus
			, CAST(CCearnings AS float) / Customers AS CCearningsPerCus
			, CAST(MFearnings AS float) / Customers AS MFearningsPerCus
			, (CAST(MFearnings AS float) + CAST(CCearnings AS float) + CAST(DDearnings AS float)) / Customers AS TotalEarningsPerCus
		FROM #PreOutput po
		WHERE NOT EXISTS (
			SELECT NULL FROM Warehouse.Staging.CustomerEngagement_ReportData x
			WHERE
				@MaxSegmentDate = x.SegmentStartDate
				AND (SELECT MAX(SegmentEndDate) FROM Warehouse.Staging.CustomerEngagement_Customer_Segment WHERE SegmentStartDate = @StartDate) = x.SegmentEndDate
				AND po.EngagementSegment = x.EngagementSegment
				AND @StartDate = x.MonthCommencing			
		);

	END

END