/******************************************************************************
Author: Jason Shipp
Created: 07/03/2019
Purpose: 
	- Load metrics for RBS Performance KPI Report
	
------------------------------------------------------------------------------
Modification History

Jason Shipp 11/04/2019
	- Added flag to identify all/credit-card-only results 

******************************************************************************/
CREATE PROCEDURE Staging.RBSPerformanceKPIReport_Load
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Load calendar table
	******************************************************************************/

	DECLARE @Today date = CAST(GETDATE() AS date);
	DECLARE @Yesterday date = DATEADD(day, -1, CAST(GETDATE() AS date));
	DECLARE @LastMonthStart date = DATEADD(month, -1, DATEADD(day, -((DATEPART(day, @Today))-1), @Today));
	DECLARE @CurrentYearStart date = DATEADD(day, -(DATEPART(dayofyear, @Today)-1), @Today);

	IF OBJECT_ID('tempdb..#Calendar') IS NOT NULL DROP TABLE #Calendar;

	SELECT 
		'LastMonth' AS PeriodType
		, @LastMonthStart AS StartDate
		, EOMONTH(@LastMonthStart) EndDate
	INTO #Calendar
	UNION ALL
	SELECT
		'YTD' AS PeriodType
		, @CurrentYearStart AS StartDate
		, @Yesterday AS EndDate
	UNION ALL
	SELECT
		'LastYear' AS PeriodType
		, DATEADD(year, -1, @CurrentYearStart) AS StartDate
		, DATEADD(day, -1, @CurrentYearStart) AS EndDate
		UNION ALL
	SELECT
		'YearBeforeLast' AS PeriodType
		, DATEADD(year, -2, @CurrentYearStart) AS StartDate
		, DATEADD(year, -1, DATEADD(day, -1, @CurrentYearStart)) AS EndDate;

	CREATE CLUSTERED INDEX CIX_Calendar ON #Calendar (EndDate, StartDate, PeriodType);

	/******************************************************************************
	Load active RBS customer counts
	******************************************************************************/

	IF OBJECT_ID('tempdb..#ActiveCustomers') IS NOT NULL DROP TABLE #ActiveCustomers;

	SELECT DISTINCT
		cal.StartDate
		, cal.EndDate
		, COUNT(c.FanID) AS ActiveCustomers
	INTO #ActiveCustomers
	FROM #Calendar cal
	INNER JOIN  Warehouse.Relational.Customer c
		ON (c.ActivatedDate <= cal.EndDate)
		AND (c.DeactivatedDate > cal.EndDate OR c.DeactivatedDate IS NULL)
	GROUP BY
		cal.PeriodType
		, cal.StartDate
		, cal.EndDate;

	IF OBJECT_ID('tempdb..#ActiveCreditCardCustomers') IS NOT NULL DROP TABLE #ActiveCreditCardCustomers;

	SELECT DISTINCT
		cal.StartDate
		, cal.EndDate
		, COUNT(DISTINCT(c.FanID)) AS ActiveCreditCardCustomers
	INTO #ActiveCreditCardCustomers
	FROM #Calendar cal
	INNER JOIN  Warehouse.Relational.Customer c
		ON (c.ActivatedDate <= cal.EndDate)
		AND (c.DeactivatedDate > cal.EndDate OR c.DeactivatedDate IS NULL)
	INNER JOIN Warehouse.Relational.CustomerPaymentMethodsAvailable pm
		ON c.FanID = pm.FanID
		AND pm.StartDate <= cal.EndDate
		AND (pm.EndDate > cal.EndDate OR pm.EndDate IS NULL)
	WHERE
		pm.PaymentMethodsAvailableID IN (1,2)
	GROUP BY
		cal.PeriodType
		, cal.StartDate
		, cal.EndDate;

	/******************************************************************************
	Load active RBS customer spend
	******************************************************************************/

	-- Load unique CINIDs

	IF OBJECT_ID('tempdb..#CINList') IS NOT NULL DROP TABLE #CINList;

	SELECT 
		cl.CINID
		, MIN(c.ActivatedDate) AS ActivatedDate
		, MAX(c.DeactivatedDate) AS DeactivatedDate
	INTO #CINList
	FROM Warehouse.Relational.Customer c
	INNER JOIN SLC_Report.dbo.Fan f
		ON c.FanID = f.ID
	INNER JOIN Warehouse.Relational.CINList cl
		ON f.SourceUID = cl.CIN
	GROUP BY
		cl.CINID;

	CREATE UNIQUE CLUSTERED INDEX CIX_CINList ON #CINList (CINID);
	CREATE NONCLUSTERED INDEX IX_CINList ON #CINList (ActivatedDate, DeactivatedDate) INCLUDE (CINID);

	-- Iterate over calendar dates and load BPD spend and transactions

	IF OBJECT_ID('tempdb..#CalendarIter') IS NOT NULL DROP TABLE #CalendarIter;
	
	SELECT DISTINCT
		StartDate
		, EndDate
		, ROW_NUMBER() OVER (ORDER BY PeriodType) AS RowNumber
	INTO #CalendarIter
	FROM #Calendar;

	DECLARE @RowNum int;
	DECLARE @MaxRowNum int;
	DECLARE @StartDate date;
	DECLARE @EndDate date;

	SET @RowNum = 1;
	SET @MaxRowNum = (SELECT MAX(RowNumber) FROM #CalendarIter);

	IF OBJECT_ID('tempdb..#BPD_TransSummary') IS NOT NULL DROP TABLE #BPD_TransSummary;

	CREATE TABLE #BPD_TransSummary (
		StartDate date NOT NULL
		, EndDate date NOT NULL
		, Spend float
		, Transactions bigint
	);		

	WHILE @RowNum <= @MaxRowNum

	BEGIN
		
		SET @StartDate = (SELECT StartDate FROM #CalendarIter WHERE RowNumber = @RowNum);
		SET @EndDate = (SELECT EndDate FROM #CalendarIter WHERE RowNumber = @RowNum);

		INSERT INTO #BPD_TransSummary (
			StartDate
			, EndDate
			, Spend
			, Transactions
		)
		SELECT 
			@StartDate
			, @EndDate
			, SUM(ct.Amount) AS Spend
			, COUNT(*) AS Transactions
		FROM Warehouse.Relational.ConsumerTransaction_MyRewards ct
		INNER JOIN #CINList cl
			ON ct.CINID = cl.CINID
		WHERE
			ct.TranDate BETWEEN @StartDate AND @EndDate
			AND cl.ActivatedDate <= @EndDate
			AND (cl.DeactivatedDate > @EndDate OR cl.DeactivatedDate IS NULL)
		OPTION (RECOMPILE);

		SET @RowNum = @RowNum + 1;
	
	END

	/******************************************************************************
	Load active RBS customer earnings
	******************************************************************************/

	SET @RowNum = 1;
	SET @MaxRowNum = (SELECT MAX(RowNumber) FROM #CalendarIter);

	IF OBJECT_ID('tempdb..#PartnerCashback') IS NOT NULL DROP TABLE #PartnerCashback;

	CREATE TABLE #PartnerCashback (
		StartDate date NOT NULL
		, EndDate date NOT NULL
		, Cashback float
		, Earners bigint
	);

	IF OBJECT_ID('tempdb..#AdditionalCashback') IS NOT NULL DROP TABLE #AdditionalCashback;

	CREATE TABLE #AdditionalCashback (
		StartDate date NOT NULL
		, EndDate date NOT NULL
		, Cashback float
		, Earners bigint
	);

	IF OBJECT_ID('tempdb..#AllCashbackEarners') IS NOT NULL DROP TABLE #AllCashbackEarners;

	CREATE TABLE #AllCashbackEarners (
		StartDate date NOT NULL
		, EndDate date NOT NULL
		, Earners bigint
	);

	WHILE @RowNum <= @MaxRowNum

	BEGIN
		
		SET @StartDate = (SELECT StartDate FROM #CalendarIter WHERE RowNumber = @RowNum);
		SET @EndDate = (SELECT EndDate FROM #CalendarIter WHERE RowNumber = @RowNum);

		-- Load retailer cashback

		INSERT INTO #PartnerCashback (
			StartDate
			, EndDate
			, Cashback
			, Earners
		)
		SELECT
			@StartDate
			, @EndDate
			, SUM(CashbackEarned) AS Cashback
			, COUNT(DISTINCT(c.FanID)) AS Earners
		FROM Warehouse.Relational.Customer c
		INNER JOIN Warehouse.Relational.PartnerTrans pt
			ON c.FanID = pt.FanID
		WHERE
			pt.TransactionDate BETWEEN @StartDate AND @EndDate
			AND c.ActivatedDate <= @EndDate
			AND (c.DeactivatedDate > @EndDate OR c.DeactivatedDate IS NULL)
		OPTION (RECOMPILE);

		-- Load additional cashback

		INSERT INTO #AdditionalCashback (
			StartDate
			, EndDate
			, Cashback
			, Earners
		)
		SELECT
			@StartDate
			, @EndDate
			, SUM(aca.CashbackEarned) AS Cashback
			, COUNT(DISTINCT(c.FanID)) AS Earners
		FROM Warehouse.Relational.Customer c
		INNER JOIN Warehouse.Relational.AdditionalCashbackAward aca
			ON c.FanID = aca.FanID
		WHERE
			aca.TranDate BETWEEN @StartDate AND @EndDate
			AND c.ActivatedDate <= @EndDate
			AND (c.DeactivatedDate > @EndDate OR c.DeactivatedDate IS NULL)
		OPTION (RECOMPILE);

		-- Load all earners

		INSERT INTO #AllCashbackEarners (
			StartDate
			, EndDate
			, Earners
		)
		SELECT
		@StartDate
		, @EndDate	
		, COUNT(*) AS Earners
		FROM (
			SELECT DISTINCT FanID FROM Warehouse.Relational.PartnerTrans pt
			WHERE pt.TransactionDate BETWEEN @StartDate AND @EndDate
			UNION 
			SELECT DISTINCT FanID FROM Warehouse.Relational.AdditionalCashbackAward aca
			WHERE aca.TranDate BETWEEN @StartDate AND @EndDate
		) x
		INNER JOIN Warehouse.Relational.Customer c
			ON x.FanID = c.FanID
		WHERE
			c.ActivatedDate <= @EndDate
			AND (c.DeactivatedDate > @EndDate OR c.DeactivatedDate IS NULL)
		OPTION (RECOMPILE);

		SET @RowNum = @RowNum + 1;
	
	END

	/******************************************************************************
	Load active RBS customer redemptions
	******************************************************************************/

	SET @RowNum = 1;
	SET @MaxRowNum = (SELECT MAX(RowNumber) FROM #CalendarIter);

	IF OBJECT_ID('tempdb..#RedemSummary') IS NOT NULL DROP TABLE #RedemSummary;

	CREATE TABLE #RedemSummary (
		StartDate date NOT NULL
		, EndDate date NOT NULL
		, RedeemType varchar(50)
		, Redemptions bigint
		, Redeemers bigint
		, CashValueRedeemed float
	);		

	WHILE @RowNum <= @MaxRowNum

	BEGIN
		
		SET @StartDate = (SELECT StartDate FROM #CalendarIter WHERE RowNumber = @RowNum);
		SET @EndDate = (SELECT EndDate FROM #CalendarIter WHERE RowNumber = @RowNum);

		INSERT INTO #RedemSummary (
			StartDate
			, EndDate
			, RedeemType
			, Redemptions
			, Redeemers
			, CashValueRedeemed
		)
		SELECT 
			@StartDate AS StartDate
			, @EndDate AS EndDate
			, 'Overall' AS RedeemType
			, COUNT(r.TranID) AS Redemtions
			, COUNT(DISTINCT(r.FanID)) AS Redeemers
			, SUM(CASE WHEN r.Cancelled = 0 THEN r.CashbackUsed ELSE CAST(0 AS int) END) AS CashValueRedeemed
		FROM Warehouse.Relational.Customer c
		INNER JOIN Warehouse.Relational.Redemptions r
			ON c.FanID = r.FanID
		WHERE
			c.ActivatedDate <= @EndDate
			AND (c.DeactivatedDate > @EndDate OR c.DeactivatedDate IS NULL)
			AND CAST(r.RedeemDate AS date) BETWEEN @StartDate AND @EndDate
			AND r.RedeemType <> 'AccClose'
		OPTION (RECOMPILE);

		INSERT INTO #RedemSummary (
			StartDate
			, EndDate
			, RedeemType
			, Redemptions
			, Redeemers
			, CashValueRedeemed
		)
		SELECT 
			@StartDate AS StartDate
			, @EndDate AS EndDate
			, r.RedeemType
			, COUNT(r.TranID) AS Redemtions
			, COUNT(DISTINCT(r.FanID)) AS Redeemers
			, SUM(CASE WHEN r.Cancelled = 0 THEN r.CashbackUsed ELSE CAST(0 AS int) END) AS CashValueRedeemed
		FROM Warehouse.Relational.Customer c
		INNER JOIN Warehouse.Relational.Redemptions r
			ON c.FanID = r.FanID
		WHERE
			c.ActivatedDate <= @EndDate
			AND (c.DeactivatedDate > @EndDate OR c.DeactivatedDate IS NULL)
			AND CAST(r.RedeemDate AS date) BETWEEN @StartDate AND @EndDate
			AND r.RedeemType <> 'AccClose'
		GROUP BY
			r.RedeemType
		OPTION (RECOMPILE);

		SET @RowNum = @RowNum + 1;
	
	END

	IF OBJECT_ID('tempdb..#RedemTypeCountSummary') IS NOT NULL DROP TABLE #RedemTypeCountSummary;

	SELECT StartDate, EndDate, [Overall], [Cash], [Trade Up], [Charity]
	INTO #RedemTypeCountSummary
	FROM 
		(
			SELECT  StartDate, EndDate, RedeemType, Redemptions
			FROM #RedemSummary
		) x
		PIVOT
		(
			MAX(Redemptions)
			FOR RedeemType IN ([Overall], [Cash], [Trade Up], [Charity])
		) p;

	/******************************************************************************
	Load RBS first time redeemers
	******************************************************************************/

	SET @RowNum = 1;
	SET @MaxRowNum = (SELECT MAX(RowNumber) FROM #CalendarIter);

	IF OBJECT_ID('tempdb..#FirstTimeRedeemers') IS NOT NULL DROP TABLE #FirstTimeRedeemers;

	CREATE TABLE #FirstTimeRedeemers (
		StartDate date NOT NULL
		, EndDate date NOT NULL
		, FirstTimeRedeemers bigint
	);		

	WHILE @RowNum <= @MaxRowNum

	BEGIN
		
		SET @StartDate = (SELECT StartDate FROM #CalendarIter WHERE RowNumber = @RowNum);
		SET @EndDate = (SELECT EndDate FROM #CalendarIter WHERE RowNumber = @RowNum);

		INSERT INTO #FirstTimeRedeemers (
			StartDate
			, EndDate
			, FirstTimeRedeemers
		)		
		SELECT	
			@StartDate
			, @EndDate
			, COUNT(DISTINCT(c.FanID)) AS FirstTimeRedeemers
		FROM Warehouse.Relational.Customer c
		INNER JOIN Warehouse.Relational.Redemptions r
			ON c.FanID = r.FanID
		WHERE
			c.ActivatedDate <= @EndDate
			AND (c.DeactivatedDate > @EndDate OR c.DeactivatedDate IS NULL)
			AND CAST(r.RedeemDate AS date) BETWEEN @StartDate AND @EndDate
			AND NOT EXISTS (
				SELECT NULL FROM Warehouse.Relational.Redemptions r2
				WHERE
					c.FanID = r2.FanID
					AND r2.RedeemDate < @StartDate
			)
		OPTION (RECOMPILE);

		SET @RowNum = @RowNum + 1;
	
	END	

	/******************************************************************************
	Load RBS web logins
	******************************************************************************/

	SET @RowNum = 1;
	SET @MaxRowNum = (SELECT MAX(RowNumber) FROM #CalendarIter);

	IF OBJECT_ID('tempdb..#Logins') IS NOT NULL DROP TABLE #Logins;

	CREATE TABLE #Logins (
		StartDate date NOT NULL
		, EndDate date NOT NULL
		, Logins bigint
		, CustomersWhoLoggedIn bigint
	);		

	WHILE @RowNum <= @MaxRowNum

	BEGIN
		
		SET @StartDate = (SELECT StartDate FROM #CalendarIter WHERE RowNumber = @RowNum);
		SET @EndDate = (SELECT EndDate FROM #CalendarIter WHERE RowNumber = @RowNum);

		INSERT INTO #Logins (
			StartDate
			, EndDate
			, Logins
			, CustomersWhoLoggedIn
		)
		SELECT	
			@StartDate
			, @EndDate
			, COUNT(wl.fanid) AS Logins
			, COUNT(DISTINCT(c.FanID)) AS CustomersWhoLoggedIn
		FROM Warehouse.Relational.Customer c
		INNER JOIN Warehouse.Relational.WebLogins wl
			ON c.FanID = wl.FanID
		WHERE
			c.ActivatedDate <= @EndDate
			AND (c.DeactivatedDate > @EndDate OR c.DeactivatedDate IS NULL)
			AND CAST(wl.trackdate AS date) BETWEEN @StartDate AND @EndDate
		OPTION (RECOMPILE);

		SET @RowNum = @RowNum + 1;
	
	END	

	/******************************************************************************
	Load RBS registrations
	******************************************************************************/

	SET @RowNum = 1;
	SET @MaxRowNum = (SELECT MAX(RowNumber) FROM #CalendarIter);

	IF OBJECT_ID('tempdb..#NewRegistrations') IS NOT NULL DROP TABLE #NewRegistrations;

	CREATE TABLE #NewRegistrations (
		StartDate date NOT NULL
		, EndDate date NOT NULL
		, Registrations bigint
	);

	IF OBJECT_ID('tempdb..#RegisteredCustomers') IS NOT NULL DROP TABLE #RegisteredCustomers;

	CREATE TABLE #RegisteredCustomers (
		StartDate date NOT NULL
		, EndDate date NOT NULL
		, RegisteredCustomers bigint
	);	

	WHILE @RowNum <= @MaxRowNum

	BEGIN
		
		SET @StartDate = (SELECT StartDate FROM #CalendarIter WHERE RowNumber = @RowNum);
		SET @EndDate = (SELECT EndDate FROM #CalendarIter WHERE RowNumber = @RowNum);

		INSERT INTO #NewRegistrations (
			StartDate
			, EndDate
			, Registrations
		)		
		SELECT	
			@StartDate
			, @EndDate
			, COUNT(DISTINCT(c.FanID)) AS Registrations
		FROM Warehouse.Relational.Customer c
		INNER JOIN Warehouse.Relational.Customer_Registered cr
			ON c.FanID = cr.FanID
		WHERE
			c.ActivatedDate <= @EndDate
			AND (c.DeactivatedDate > @EndDate OR c.DeactivatedDate IS NULL)
			AND cr.StartDate BETWEEN @StartDate AND @EndDate
			AND cr.Registered = 1
		OPTION (RECOMPILE);

		INSERT INTO #RegisteredCustomers (
			StartDate
			, EndDate
			, RegisteredCustomers
		)		
		SELECT	
			@StartDate
			, @EndDate
			, COUNT(DISTINCT(c.FanID)) AS RegisteredCustomers
		FROM Warehouse.Relational.Customer c
		INNER JOIN Warehouse.Relational.Customer_Registered cr
			ON c.FanID = cr.FanID
		WHERE
			c.ActivatedDate <= @EndDate
			AND (c.DeactivatedDate > @EndDate OR c.DeactivatedDate IS NULL)
			AND cr.StartDate <= @EndDate
			AND (cr.EndDate > @EndDate OR cr.EndDate IS NULL)
			AND cr.Registered = 1
		OPTION (RECOMPILE);

		SET @RowNum = @RowNum + 1;
	
	END	

	/******************************************************************************
	Load RBS marketable customers
	******************************************************************************/

	SET @RowNum = 1;
	SET @MaxRowNum = (SELECT MAX(RowNumber) FROM #CalendarIter);

	IF OBJECT_ID('tempdb..#Marketable') IS NOT NULL DROP TABLE #Marketable;

	CREATE TABLE #Marketable (
		StartDate date NOT NULL
		, EndDate date NOT NULL
		, MarketableCustomers bigint
	);		

	IF OBJECT_ID('tempdb..#RegisteredMarketable') IS NOT NULL DROP TABLE #RegisteredMarketable;

	CREATE TABLE #RegisteredMarketable (
		StartDate date NOT NULL
		, EndDate date NOT NULL
		, RegisteredMarketable bigint
	);	
	
	WHILE @RowNum <= @MaxRowNum

	BEGIN
		
		SET @StartDate = (SELECT StartDate FROM #CalendarIter WHERE RowNumber = @RowNum);
		SET @EndDate = (SELECT EndDate FROM #CalendarIter WHERE RowNumber = @RowNum);

		INSERT INTO #Marketable (
			StartDate
			, EndDate
			, MarketableCustomers
		)
		SELECT	
			@StartDate
			, @EndDate
			, COUNT(DISTINCT(c.FanID)) AS MarketableCustomers
		FROM Warehouse.Relational.Customer c
		INNER JOIN Warehouse.Relational.Customer_MarketableByEmailStatus m
			ON c.FanID = m.FanID
		WHERE
			c.ActivatedDate <= @EndDate
			AND (c.DeactivatedDate > @EndDate OR c.DeactivatedDate IS NULL)
			AND m.StartDate <= @EndDate
			AND (m.EndDate > @EndDate OR m.EndDate IS NULL)
			AND m.MarketableByEmail = 1
		OPTION (RECOMPILE);

		INSERT INTO #RegisteredMarketable (
			StartDate
			, EndDate
			, RegisteredMarketable
		)
		SELECT	
			@StartDate
			, @EndDate
			, COUNT(DISTINCT(c.FanID)) AS RegisteredMarketable
		FROM Warehouse.Relational.Customer c
		INNER JOIN Warehouse.Relational.Customer_Registered cr
			ON c.FanID = cr.FanID
		INNER JOIN Warehouse.Relational.Customer_MarketableByEmailStatus m
			ON c.FanID = m.FanID
		WHERE
			c.ActivatedDate <= @EndDate
			AND (c.DeactivatedDate > @EndDate OR c.DeactivatedDate IS NULL)
			AND cr.StartDate <= @EndDate
			AND (cr.EndDate > @EndDate OR cr.EndDate IS NULL)
			AND m.StartDate <= @EndDate
			AND (m.EndDate > @EndDate OR m.EndDate IS NULL)
			AND cr.Registered = 1
			AND m.MarketableByEmail = 1
		OPTION (RECOMPILE);

		SET @RowNum = @RowNum + 1;
	
	END	

	/******************************************************************************
	Load all metrics into Warehouse.Staging.RBSPerformanceKPIReport_Results table

	-- Create table for storing results

	CREATE TABLE Warehouse.Staging.RBSPerformanceKPIReport_Results (
		ID int NOT NULL IDENTITY (1,1)
		, ReportDate date NOT NULL
		, IsCreditCardResults bit NOT NULL
		, PeriodType varchar(50) NOT NULL
		, StartDate date NOT NULL
		, EndDate date NOT NULL
		, ActiveCustomers int
		, NewActiveCustomersYTD int
		, ActiveCreditCardCustomers int
		, NewActiveCreditCardCustomersYTD int
		, ActiveCustomerSpend money
		, AverageActiveCustomerSpend money
		, PartnerCashbackEarned money
		, BankFundedCashbackEarned money
		, TotalCashbackEarned money
		, AveragePartnerCashbackEarned money
		, AverageBankFundedCashbackEarned money
		, AverageTotalCashbackEarned money
		, Redemptions int
		, CashValueRedeemed money
		, AverageCustomerRedemptions float
		, AverageCustomerCashValueRedeemed money
		, CashValueRedeemedProportionOfTotalEarned float
		, Redeemers int
		, FirstTimeRedeemers int
		, ProportionFirstTimeRedeemers float
		, ProportionCashRedemptions float
		, ProportionTradeUpRedemptions float
		, ProportionCharityRedemptions float
		, ProportionActiveCustomersRedeemed float
		, Logins int
		, CustomersWhoLoggedIn int
		, ProportionActiveCustomersLoggedIn float
		, AverageActiveCustomerLogins float
		, Registrations int		
		, RegisteredCustomers int
		, ProportionActiveCustomersRegistered float
		, MarketableCustomers int
		, ProportionActiveCustomersMarketable float
		, ActiveCustomersRegisteredMarketable int
		, ProportionActiveCustomersRegisteredMarketable float
		, CONSTRAINT PK_RBSPerformanceKPIReport_Results PRIMARY KEY (ID) 
	)
	******************************************************************************/

	DECLARE @NewActiveCustomersYTD int = 
	(SELECT MAX(ActiveCustomers) FROM #ActiveCustomers WHERE EndDate = @Yesterday) - (SELECT MAX(ActiveCustomers) FROM #ActiveCustomers WHERE EndDate = DATEADD(day, -1, @CurrentYearStart));

	DECLARE @NewActiveCreditCardCustomersYTD int = 
	(SELECT MAX(ActiveCreditCardCustomers) FROM #ActiveCreditCardCustomers WHERE EndDate = @Yesterday) - (SELECT MAX(ActiveCreditCardCustomers) FROM #ActiveCreditCardCustomers WHERE EndDate = DATEADD(day, -1, @CurrentYearStart));

	INSERT INTO Warehouse.Staging.RBSPerformanceKPIReport_Results (
		ReportDate
		, IsCreditCardResults
		, PeriodType
		, StartDate
		, EndDate
		, ActiveCustomers
		, NewActiveCustomersYTD
		, ActiveCreditCardCustomers
		, NewActiveCreditCardCustomersYTD
		, ActiveCustomerSpend
		, AverageActiveCustomerSpend
		, PartnerCashbackEarned
		, BankFundedCashbackEarned
		, TotalCashbackEarned
		, AveragePartnerCashbackEarned
		, AverageBankFundedCashbackEarned
		, AverageTotalCashbackEarned
		, Redemptions
		, CashValueRedeemed
		, AverageCustomerRedemptions
		, AverageCustomerCashValueRedeemed
		, CashValueRedeemedProportionOfTotalEarned
		, Redeemers
		, FirstTimeRedeemers
		, ProportionFirstTimeRedeemers
		, ProportionCashRedemptions
		, ProportionTradeUpRedemptions
		, ProportionCharityRedemptions
		, ProportionActiveCustomersRedeemed
		, Logins
		, CustomersWhoLoggedIn
		, ProportionActiveCustomersLoggedIn
		, AverageActiveCustomerLogins
		, Registrations
		, RegisteredCustomers
		, ProportionActiveCustomersRegistered
		, MarketableCustomers
		, ProportionActiveCustomersMarketable
		, ActiveCustomersRegisteredMarketable
		, ProportionActiveCustomersRegisteredMarketable
	)
	SELECT
		@Today AS ReportDate
		, 0 AS IsCreditCardResults
		, cal.PeriodType
		, cal.StartDate
		, cal.EndDate
		, ac.ActiveCustomers
		, CASE WHEN cal.PeriodType = 'YTD' THEN @NewActiveCustomersYTD ELSE NULL END AS NewActiveCustomersYTD
		, accc.ActiveCreditCardCustomers
		, CASE WHEN cal.PeriodType = 'YTD' THEN @NewActiveCreditCardCustomersYTD ELSE NULL END AS NewActiveCreditCardCustomersYTD
		, bpdt.Spend AS ActiveCustomerSpend
		, ISNULL(bpdt.Spend/NULLIF(CAST(ac.ActiveCustomers AS float), 0), 0) AS AverageActiveCustomerSpend
		, pcb.Cashback AS PartnerCashbackEarned
		, acb.Cashback AS BankFundedCashbackEarned
		, pcb.Cashback + acb.Cashback AS TotalCashbackEarned
		, ISNULL(pcb.Cashback/NULLIF(CAST(pcb.Earners AS float), 0), 0) AS AveragePartnerCashbackEarned
		, ISNULL(acb.Cashback/NULLIF(CAST(acb.Earners AS float), 0), 0) AS AverageBankFundedCashbackEarned
		, ISNULL((pcb.Cashback + acb.Cashback)/NULLIF(CAST(acbe.Earners AS float), 0), 0) AS AverageTotalCashbackEarned
		, rs.Redemptions
		, rs.CashValueRedeemed
		, ISNULL(rs.Redemptions/NULLIF(CAST(rs.Redeemers AS float), 0), 0) AS AverageCustomerRedemptions
		, ISNULL(rs.CashValueRedeemed/NULLIF(CAST(rs.Redeemers AS float), 0), 0) AS AverageCustomerCashValueRedeemed
		, ISNULL((rs.CashValueRedeemed)/NULLIF(CAST((pcb.Cashback + acb.Cashback) AS float), 0), 0) AS CashValueRedeemedProportionOfTotalEarned
		, rs.Redeemers
		, ftr.FirstTimeRedeemers
		, ISNULL((ftr.FirstTimeRedeemers)/NULLIF(CAST(rs.Redeemers AS float), 0), 0) AS ProportionFirstTimeRedeemers
		, ISNULL((rtcs.Cash)/NULLIF(CAST((rtcs.Overall) AS float), 0), 0) AS ProportionCashRedemptions
		, ISNULL((rtcs.[Trade Up])/NULLIF(CAST((rtcs.Overall) AS float), 0), 0) AS ProportionTradeUpRedemptions
		, ISNULL((rtcs.Charity)/NULLIF(CAST((rtcs.Overall) AS float), 0), 0) AS ProportionCharityRedemptions
		, ISNULL(rs.Redeemers/NULLIF(CAST(ac.ActiveCustomers AS float), 0), 0) AS ProportionActiveCustomersRedeemed
		, l.Logins
		, l.CustomersWhoLoggedIn
		, ISNULL(l.CustomersWhoLoggedIn/NULLIF(CAST(ac.ActiveCustomers AS float), 0), 0) AS ProportionActiveCustomersLoggedIn
		, ISNULL(l.Logins/NULLIF(CAST(l.CustomersWhoLoggedIn AS float), 0), 0) AS AverageActiveCustomerLogins
		, nr.Registrations
		, rc.RegisteredCustomers
		, ISNULL(rc.RegisteredCustomers/NULLIF(CAST(ac.ActiveCustomers AS float), 0), 0) AS ProportionActiveCustomersRegistered
		, m.MarketableCustomers
		, ISNULL(m.MarketableCustomers/NULLIF(CAST(ac.ActiveCustomers AS float), 0), 0) AS ProportionActiveCustomersMarketable
		, rm.RegisteredMarketable AS ActiveCustomersRegisteredMarketable
		, ISNULL(rm.RegisteredMarketable/NULLIF(CAST(ac.ActiveCustomers AS float), 0), 0) AS ProportionActiveCustomersRegisteredMarketable
	FROM #Calendar cal
	LEFT JOIN #ActiveCustomers ac
		ON cal.StartDate = ac.StartDate
		AND cal.EndDate = ac.EndDate
	LEFT JOIN #ActiveCreditCardCustomers accc
		ON cal.StartDate = accc.StartDate
		AND cal.EndDate = accc.EndDate
	LEFT JOIN #BPD_TransSummary bpdt
		ON cal.StartDate = bpdt.StartDate
		AND cal.EndDate = bpdt.EndDate
	LEFT JOIN #PartnerCashback pcb
		ON cal.StartDate = pcb.StartDate
		AND cal.EndDate = pcb.EndDate
	LEFT JOIN #AdditionalCashback acb
		ON cal.StartDate = acb.StartDate
		AND cal.EndDate = acb.EndDate
	LEFT JOIN #AllCashbackEarners acbe
		ON cal.StartDate = acbe.StartDate
		AND cal.EndDate = acbe.EndDate
	LEFT JOIN #RedemSummary rs
		ON cal.StartDate = rs.StartDate
		AND cal.EndDate = rs.EndDate
		AND rs.RedeemType = 'Overall'
	LEFT JOIN #RedemTypeCountSummary rtcs
		ON cal.StartDate = rtcs.StartDate
		AND cal.EndDate = rtcs.EndDate
	LEFT JOIN #FirstTimeRedeemers ftr
		ON cal.StartDate = ftr.StartDate
		AND cal.EndDate = ftr.EndDate
	LEFT JOIN #Logins l
		ON cal.StartDate = l.StartDate
		AND cal.EndDate = l.EndDate
	LEFT JOIN #NewRegistrations nr
		ON cal.StartDate = nr.StartDate
		AND cal.EndDate = nr.EndDate
	LEFT JOIN #RegisteredCustomers rc
		ON cal.StartDate = rc.StartDate
		AND cal.EndDate = rc.EndDate
	LEFT JOIN #Marketable m
		ON cal.StartDate = m.StartDate
		AND cal.EndDate = m.EndDate
	LEFT JOIN #RegisteredMarketable rm
		ON cal.StartDate = rm.StartDate
		AND cal.EndDate = rm.EndDate
	WHERE NOT EXISTS (
		SELECT NULL FROM Warehouse.Staging.RBSPerformanceKPIReport_Results r
			WHERE
			r.IsCreditCardResults = 0
			AND cal.PeriodType = r.PeriodType
			AND cal.StartDate = r.StartDate
			AND cal.EndDate = r.EndDate
			AND r.ReportDate = @Today
	);

END