/******************************************************************************
Author: Jason Shipp
Created: 14/11/2019
Purpose: 
	- For Reward 3.0 reporting
	- Loads, overwriting for the current month and last month (depending on how far into the month this is run), account start, end, first and last earn dates
	, as well as earnings data into the Warehouse.Relational.Reward3Point0_AccountEarnings table for a publisher
	- Includes demographic data and account type per nominee 
	
------------------------------------------------------------------------------
Modification History

Jason Shipp 30/03/2020
	- Swapped IssuerBankAccountID (account holder ID) for BankAccountID (bank account ID) in grouping logic. 
	- Added check to ensure members have an open bank account in each analysis period (with leeway to cope with incomplete bank account data in SLC)
	- Based demographics on the most recent nominee associated with each bank account

	This mod is from a fresh copy of Reward3Point0_AccountsEarnings_Load taken on 28/04/2022
******************************************************************************/
CREATE PROCEDURE [Relational].[Reward3Point0_AccountsEarnings_Load_CJM] (@PublisherID int, @AnalysisStartDate date)
	
AS
BEGIN
	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON

	DECLARE @Time DATETIME
		  , @Msg VARCHAR(2048)
		  , @RowsProcessed INT 
		  , @SSMS BIT = 1 

	SET @Msg = 'Reward3Point0_AccountsEarnings_Load_CJM'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT

	/******************************************************************************
	Declare variables
	******************************************************************************/
	--IF 1 = 1 BEGIN -- testing
	--DECLARE @PublisherID int = 132; -- For testing; 132 = Natwest, 138 = RBS etc.
	--DECLARE @AnalysisStartDate date = '2020-02-01'; -- 3.0 go live date
	--END

	DECLARE @Today date = CAST(GETDATE() AS date);
	DECLARE @RefreshFromDate date;
	
	IF DATEPART(day, @Today) <= 10 -- If today is less than the 10th of the month, refresh data for this month and last month. Otherwise, just refresh this month
		SET @RefreshFromDate = DATEADD(month, -2, DATEADD(day, 1, EOMONTH(@Today)))
	ELSE
		SET @RefreshFromDate = DATEADD(month, -1, DATEADD(day, 1, EOMONTH(@Today)));

	/******************************************************************************
	Load linking table to link IssuerIDs to PublisherIDs
	******************************************************************************/

	IF OBJECT_ID('tempdb..#IssuerPublisher') IS NOT NULL DROP TABLE #IssuerPublisher;

	SELECT
		i.ID AS IssuerID
		, i.Name
		, c.ID AS PublisherID
	INTO #IssuerPublisher
	FROM SLC_Report.dbo.Issuer i
	INNER JOIN SLC_Report.dbo.Club c
		ON (i.Name = c.Abbreviation OR i.Name = c.Nickname)
	WHERE c.ID = @PublisherID;

	DECLARE @PublisherName varchar(50) = (SELECT Name FROM #IssuerPublisher);

	SELECT * FROM #IssuerPublisher

	/******************************************************************************
	Load age buckets
	******************************************************************************/

	IF OBJECT_ID('tempdb..#AgeBuckets') IS NOT NULL DROP TABLE #AgeBuckets;
	CREATE TABLE #AgeBuckets (StartAge int, EndAge int, BucketName varchar(50));
	INSERT INTO #AgeBuckets (StartAge, EndAge, BucketName)
	VALUES
	(18, 24, '18-24')
	, (25, 34, '25-34')
	, (35, 44, '35-44')
	, (45, 54, '45-54')
	, (55, 64, '55-64')
	, (65, 80, '65-80')
	, (81, 200, '81+');

	CREATE UNIQUE CLUSTERED INDEX UNCIX_AgeBuckets ON #AgeBuckets (StartAge, EndAge);


	/******************************************************************************
	Load calendar table
	******************************************************************************/

	IF OBJECT_ID('tempdb..#Calendar') IS NOT NULL DROP TABLE #Calendar;
	;WITH 
		E1 AS (SELECT n = 0 FROM (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) d (n)),
		E2 AS (SELECT n = 0 FROM E1 a CROSS JOIN E1 b),
		Tally AS (
			SELECT TOP(1+DATEDIFF(MONTH,@AnalysisStartDate,@Today)) 
				n = ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) 
			FROM E2 a CROSS JOIN E2 b) -- Create table of numbers
		SELECT 
			RowNumber = n, 
			x.StartDate,
			EndDate = CAST(CASE WHEN EOMONTH(x.StartDate) >= @Today THEN DATEADD(day, -1, @Today) ELSE EOMONTH(x.StartDate) END AS DATE),
			PeriodType = 'Month'
		INTO #Calendar
		FROM Tally t
		CROSS APPLY (SELECT StartDate = CAST(DATEADD(month,n-1,DATEADD(MONTH,DATEDIFF(MONTH,0,@AnalysisStartDate),0)) AS DATE)) x
		WHERE x.StartDate < @Today

	CREATE UNIQUE CLUSTERED INDEX ucx_Calendar ON #Calendar (StartDate, EndDate);

	SET @Msg = 'Calendar generated'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT


	/******************************************************************************
	Load scheme member demographics and linked bank account type history
	******************************************************************************/

	IF OBJECT_ID('tempdb..#CustomerAccounts') IS NOT NULL DROP TABLE #CustomerAccounts;
	CREATE TABLE #CustomerAccounts (
		FanID INT, IssuerCustomerID INT, Gender varchar(1), DOB DATE, Postcode VARCHAR(10), 
		PublisherID INT, PublisherName VARCHAR(50), SourceUID VARCHAR(20), BankAccountID INT,
		IssuerBankAccountID INT, AccountTypeStart DATE, AccountTypeEnd DATE,
		ProductCode VARCHAR(20), ProductName VARCHAR(40), IsJointAccount BIT	
	)
	CREATE CLUSTERED INDEX cx_CustomerAccounts ON #CustomerAccounts (IssuerCustomerID, BankAccountID);

	INSERT INTO #CustomerAccounts WITH (TABLOCK) (
		FanID, IssuerCustomerID, Gender, DOB, Postcode,
		PublisherID, PublisherName, SourceUID, BankAccountID,
		IssuerBankAccountID, AccountTypeStart, AccountTypeEnd,
		ProductCode, ProductName, IsJointAccount	
	)
	SELECT
		f.ID AS FanID
		, ic.ID AS IssuerCustomerID
		, CAST (
			CASE f.Sex 
				WHEN 1 THEN 'M'
				WHEN 2 THEN 'F'
				ELSE 'U'
			END 
		AS varchar(1)
		) AS Gender
		, CAST(f.DOB AS date) AS DOB
		, f.Postcode
		, f.ClubID AS PublisherID
		, ip.Name AS PublisherName
		, f.SourceUID
		, iba.BankAccountID
		, iba.ID AS IssuerBankAccountID
		, CAST(bh.StartDate AS date) AS AccountTypeStart
		, CAST(bh.EndDate AS date) AS AccountTypeEnd
		, o.ProductCode
		, o.ProductName
		, CASE WHEN x.AccountHolders >1 THEN 1 ELSE 0 END AS IsJointAccount
	FROM SLC_Report.dbo.Fan f -- Scheme members
	INNER JOIN #IssuerPublisher ip -- Create link between member ClubID and IssuerID
		ON f.ClubID = ip.PublisherID
	INNER JOIN SLC_Report.dbo.IssuerCustomer ic -- Link scheme members to issuer (bank) customer IDs
		ON	f.SourceUID = ic.SourceUID
		AND ip.IssuerID = ic.IssuerID
	INNER JOIN SLC_Report.dbo.IssuerBankAccount iba -- Link issuer (bank) customer IDs to their bank account(s)
		ON ic.ID = iba.IssuerCustomerID
	INNER JOIN SLC_Report.dbo.BankAccountTypeHistory bh -- Link bank accounts to bank accounts history (Ie. to get changes in account type over time)
		ON iba.BankAccountID = bh.BankAccountID
	INNER JOIN (SELECT DISTINCT ProductCode, BankID, ProductName FROM Warehouse.Relational.AccountType_Offers) o -- Get the type of each bank account
		ON bh.[Type] = o.ProductCode
		AND ip.PublisherID = o.BankID
	OUTER APPLY (
		SELECT 
			iba2.BankAccountID,
			COUNT(DISTINCT iba2.IssuerCustomerID) AS AccountHolders
		FROM SLC_Report.dbo.IssuerBankAccount iba2
		WHERE iba.BankAccountID = iba2.BankAccountID
		GROUP BY iba2.BankAccountID
	) x
	ORDER BY IssuerCustomerID, BankAccountID;
	SET @RowsProcessed = @@ROWCOUNT;

	SET @Msg = '#CustomerAccounts generated and indexed [' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows]'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT
	-- [4648347 rows] / 00:01:11



	-- Load demographics of most recent account nominee associated with each bank account
	IF OBJECT_ID('tempdb..#Demographics') IS NOT NULL DROP TABLE #Demographics;
	WITH DemographicsStaging AS (
		SELECT
			nn.BankAccountID
			, nn.StartDate
			, MAX(nn.StartDate) OVER (PARTITION BY nn.BankAccountID) AS MaxBankAccountNomineeStartDate
			, a.FanID AS NomineeFanID
			, a.Gender
			, a.DOB
			, a.Postcode
		FROM #CustomerAccounts a
		INNER JOIN SLC_Report.dbo.DDCashbackNominee nn
			ON a.IssuerCustomerID = nn.IssuerCustomerID
	)
	SELECT DISTINCT
		ds.BankAccountID
		, ds.NomineeFanID
		, ds.Gender
		, ds.DOB
		, ds.Postcode
	INTO #Demographics
	FROM DemographicsStaging ds
	WHERE ds.MaxBankAccountNomineeStartDate = ds.StartDate;
	SET @RowsProcessed = @@ROWCOUNT;
	
	CREATE UNIQUE CLUSTERED INDEX ucx_Demographics ON #Demographics (BankAccountID);

	SET @Msg = '#Demographics generated and indexed [' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows]'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT
	-- [3269127 rows] / 00:00:21



	-- Get the transaction type (mobile login/non-mobile login etc.)
	IF OBJECT_ID('tempdb..#RewardThreeTranTypes') IS NOT NULL DROP TABLE #RewardThreeTranTypes;
	SELECT 
		tt.ID, 
		tt.Name,
		EarningType = CASE 
			WHEN tt.Name LIKE ('%Direct Debit%') THEN 'DD'
			WHEN tt.Name LIKE ('%Mobile%') THEN 'MobileLogin'
			ELSE NULL END,
		tt.Multiplier
	INTO #RewardThreeTranTypes
	FROM SLC_Report.dbo.TransactionType tt			
	WHERE tt.[Description] LIKE '%Reward 3.0%' -- Reward 3.0 earnings only
		AND tt.Multiplier = 1
	SET @RowsProcessed = @@ROWCOUNT;
	
	SET @Msg = '#RewardThreeTranTypes grabbed [' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows]'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT



	/******************************************************************************
	Load account holder start, end, first and last earn dates
	******************************************************************************/

	-- Load most recent account types per IssuerBankAccountID
	IF OBJECT_ID('tempdb..#MostRecentAccountType') IS NOT NULL DROP TABLE #MostRecentAccountType;
	CREATE TABLE #MostRecentAccountType (IssuerBankAccountID INT, ProductCode VARCHAR(50), ProductName VARCHAR(50))
	CREATE UNIQUE CLUSTERED INDEX ucx_MostRecentAccountType ON #MostRecentAccountType (IssuerBankAccountID);

	INSERT INTO #MostRecentAccountType (IssuerBankAccountID, ProductCode, ProductName)
	SELECT DISTINCT
		a.IssuerBankAccountID
		, a.ProductCode
		, a.ProductName
	FROM (
		SELECT 
			a.IssuerBankAccountID
			, a.AccountTypeEnd
			, CASE -- If IssuerBankAccountID has any NULL end dates, maintain a NULL value when using the MAX function
				WHEN MAX(CASE WHEN a.AccountTypeEnd IS NULL THEN 1 ELSE 0 END) OVER (PARTITION BY a.IssuerBankAccountID) = 0 
				THEN MAX(a.AccountTypeEnd) OVER (PARTITION BY a.IssuerBankAccountID)
				ELSE NULL
			END AS MaxAccountEnd
			, a.ProductCode
			, a.ProductName
		FROM #CustomerAccounts a	
	) a
	WHERE (a.AccountTypeEnd = a.MaxAccountEnd OR a.AccountTypeEnd IS NULL AND a.MaxAccountEnd IS NULL);	
	SET @RowsProcessed = @@ROWCOUNT;

	SET @Msg = '#MostRecentAccountType generated and indexed [' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows]'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT
	-- [4,228,338 rows] / 00:00:17


	-- Load unique account holders
	IF OBJECT_ID('tempdb..#UniqueAccounts') IS NOT NULL DROP TABLE #UniqueAccounts;
	SELECT
		mra.IssuerBankAccountID
		, a.BankAccountID
		, a.PublisherID
		, a.PublisherName
		, mra.ProductCode AS MostRecentAccountTypeCode
		, mra.ProductName AS MostRecentAccountType
		, a.IsJointAccount
		, a.NomineeFanID
		, a.Gender
		, a.DOB
		, a.Postcode
		, a.AccountStartDate
		, a.AccountEndDate
	INTO #UniqueAccounts
	FROM #MostRecentAccountType mra
	CROSS APPLY (
		SELECT 
			PublisherID = MIN(a.PublisherID),
			PublisherName = MIN(a.PublisherName),
			BankAccountID = MIN(a.BankAccountID),
			IsJointAccount = MIN(CAST(a.IsJointAccount AS TINYINT)),
			NomineeFanID = MIN(dem.NomineeFanID),
			Gender = MIN(dem.Gender),
			DOB = MIN(dem.DOB),
			Postcode = MIN(dem.Postcode),
			AccountStartDate = MIN(a.AccountTypeStart), 
			AccountEndDate = CASE -- If IssuerBankAccountID has any NULL end dates, maintain a NULL value when using the MAX function
				WHEN MAX(CASE WHEN a.AccountTypeEnd IS NULL THEN 10 ELSE 0 END) = 0 
				THEN MAX(a.AccountTypeEnd)
				ELSE NULL
			END
		FROM #CustomerAccounts a
		LEFT JOIN #Demographics dem
			ON a.BankAccountID = dem.BankAccountID
		WHERE a.IssuerBankAccountID = mra.IssuerBankAccountID
		GROUP BY a.IssuerBankAccountID
	) a;	
	SET @RowsProcessed = @@ROWCOUNT;

	CREATE UNIQUE CLUSTERED INDEX ucx_UniqueAccounts ON #UniqueAccounts (IssuerBankAccountID);

	SET @Msg = '#UniqueAccounts generated and indexed [' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows]'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT
	-- [4,228,338 rows] / 00:00:30



	-- Combine unique account holders and first/last earn dates on each account
	IF OBJECT_ID('tempdb..#UniqueAccountEarnDateRange') IS NOT NULL DROP TABLE #UniqueAccountEarnDateRange;
	SELECT 
		a.PublisherID
		, a.PublisherName
		, a.IssuerBankAccountID
		, a.BankAccountID
		, a.MostRecentAccountTypeCode
		, a.MostRecentAccountType
		, a.AccountStartDate
		, a.AccountEndDate
		, a.IsJointAccount
		, a.NomineeFanID
		, a.Gender
		, a.DOB
		, a.Postcode
		, x.DDMinEarningDate			
		, x.MobileLoginMinEarningDate
		, x.DDMaxEarningDate
		, x.MobileLoginMaxEarningDate
		, PostcodeDistrict = CASE WHEN (CHARINDEX(' ', a.Postcode) > 0) THEN LEFT(a.Postcode, (CHARINDEX(' ', a.Postcode)-1)) ELSE NULL END
		, Region = ISNULL(ons.Region, pa.Region)
	INTO #UniqueAccountEarnDateRange
	FROM #UniqueAccounts a
	LEFT JOIN (
		SELECT t.IssuerBankAccountID,
			DDMinEarningDate = MIN(CASE WHEN tt.EarningType = 'DD' THEN t.[Date] ELSE NULL END), 
			MobileLoginMinEarningDate = MIN(CASE WHEN tt.EarningType = 'MobileLogin' THEN t.[Date] ELSE NULL END),
			DDMaxEarningDate = MAX(CASE WHEN tt.EarningType = 'DD' THEN t.[Date] ELSE NULL END),
			MobileLoginMaxEarningDate = MAX(CASE WHEN tt.EarningType = 'MobileLogin' THEN t.[Date] ELSE NULL END) 
		FROM SLC_Report.dbo.Trans t				
		INNER JOIN #RewardThreeTranTypes tt		
			ON tt.ID = t.TypeID   
		WHERE t.[Date] >= @AnalysisStartDate
			AND t.ClubCash > 0
		GROUP BY t.IssuerBankAccountID
	) x ON x.IssuerBankAccountID = a.IssuerBankAccountID
	LEFT JOIN Warehouse.Staging.ONSPostcodeImport ons
		ON REPLACE(a.Postcode, ' ', '') = REPLACE(ons.Postcode, ' ', '')
	LEFT JOIN Warehouse.Relational.PostArea pa
		ON (CASE WHEN PATINDEX('%[0-9]%', a.Postcode) > 0 THEN LEFT(a.Postcode, PATINDEX('%[0-9]%', a.Postcode)-1) ELSE a.Postcode END) = pa.PostAreaCode;
	SET @RowsProcessed = @@ROWCOUNT;

	CREATE UNIQUE CLUSTERED INDEX UCIX_UniqueAccountEarnDates ON #UniqueAccountEarnDateRange (IssuerBankAccountID); -- Ensure uniqueness

	SET @Msg = '#UniqueAccountEarnDateRange generated and indexed [' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows]'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT
	-- [4,228,338 rows] / 00:00:51




	/******************************************************************************
	QA: check bank account type history dates don't overlap, and check nominee dates don't overlap 
	******************************************************************************/

	-- Load nominee history associated with bank account type history
	IF OBJECT_ID('tempdb..#CustomerAccountNominee') IS NOT NULL DROP TABLE #CustomerAccountNominee;
	SELECT	DISTINCT
		ca.IssuerBankAccountID
		,	ca.AccountTypeStart
		,	ca.AccountTypeEnd
		,	CAST(nn.StartDate AS date) AS IssuerCustomerIDStart
		,	CAST(nn.EndDate AS date) AS IssuerCustomerIDEnd
	INTO #CustomerAccountNominee
	FROM #CustomerAccounts ca
	LEFT JOIN SLC_Report.dbo.DDCashbackNominee nn
		ON ca.BankAccountID = nn.BankAccountID
		AND ca.IssuerCustomerID = nn.IssuerCustomerID;
	SET @RowsProcessed = @@ROWCOUNT; 	

	CREATE CLUSTERED INDEX ix_Stuff ON #CustomerAccountNominee ([IssuerBankAccountID],[IssuerCustomerIDStart])

	SET @Msg = '#CustomerAccountNominee generated and indexed [' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows]'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT
	-- [5,511,744 rows] / 00:00:30


	DECLARE @NumOverlappingDates int = (
		( -- Count overlapping IssuerBankAccountID account type dates
			SELECT COUNT(*) FROM #CustomerAccountNominee dr1
			INNER JOIN #CustomerAccountNominee dr2
				ON dr1.IssuerBankAccountID = dr2.IssuerBankAccountID
				AND dr2.AccountTypeStart > dr1.AccountTypeStart -- Start date after another IssuerBankAccountID start date
				AND (dr2.AccountTypeStart < dr1.AccountTypeEnd OR dr1.AccountTypeEnd IS NULL) -- Start date before another IssuerBankAccountID end date
		)
		+ ( -- Count overlapping IssuerBankAccountID nominee dates
			SELECT COUNT(*) FROM #CustomerAccountNominee dr1
			INNER JOIN #CustomerAccountNominee dr2
				ON dr1.IssuerBankAccountID = dr2.IssuerBankAccountID
				AND dr2.IssuerCustomerIDStart > dr1.IssuerCustomerIDStart -- Start date after another IssuerBankAccountID start date
				AND (dr2.IssuerCustomerIDStart < dr1.IssuerCustomerIDEnd OR dr1.IssuerCustomerIDEnd IS NULL) -- Start date before another IssuerBankAccountID end date
		) 
	);
	-- 1 / 00:00:07

	IF @NumOverlappingDates >0 RAISERROR('Overlapping IssuerBankAccountID dates in #CustomerAccountNominee- this will create duplication errors', 16, 1);

	SET @Msg = 'Count of overlapping IssuerBankAccountID account type dates is [' + CAST(@NumOverlappingDates AS VARCHAR(6)) + ']'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT




	/******************************************************************************
	Delete earnings data from results table for the last 1 or 2 months (depending on today's date) and over 2 yeas old, iterating per period for efficiency 
	******************************************************************************/

	IF OBJECT_ID('tempdb..#CalForDelete') IS NOT NULL DROP TABLE #CalForDelete;
	SELECT 
		StartDate
		, EndDate
		, PeriodType
		, ROW_NUMBER() OVER (ORDER BY StartDate DESC) AS RowNumber
	INTO #CalForDelete
	FROM #Calendar
	WHERE (StartDate >= @RefreshFromDate) -- Delete most recent 2 months' data
		OR (StartDate <= DATEADD(month, -25, @Today)); -- Delete data over 2 years old

	DECLARE @RowNumDel int = 1;
	DECLARE @MaxRowNumDel int = (SELECT MAX(RowNumber) FROM #CalForDelete);

	WHILE @RowNumDel <= @MaxRowNumDel BEGIN

		DELETE t
		FROM Warehouse.Relational.Reward3Point0_AccountEarnings_CJM t
		INNER JOIN #CalForDelete d
			ON t.PublisherID = @PublisherID
			AND t.StartDate = d.StartDate
			AND t.EndDate <= d.EndDate			 
			AND t.PeriodType = d.PeriodType		
		WHERE d.RowNumber = @RowNumDel;

		SET @RowNumDel = @RowNumDel + 1

	END
	-- ? / 00:01:15
	SET @Msg = 'Delete earnings data from results table for the last 1 or 2 months'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT



	/******************************************************************************
	Set up for iterating over analysis periods
	******************************************************************************/

	-- Remove analysis periods over 2 years old
	DELETE FROM #Calendar WHERE StartDate <= DATEADD(month, -25, @Today);

	-- Remove analysis periods associated with data in results table
	DELETE c
	FROM #Calendar c
	WHERE EXISTS (
		SELECT NULL 
		FROM Warehouse.Relational.Reward3Point0_AccountEarnings_CJM d 
		WHERE c.StartDate = d.StartDate
		AND c.EndDate = d.EndDate
		AND c.PeriodType = d.PeriodType
		AND d.PublisherID = @PublisherID);

	-- Reorder analysis periods	
	;WITH UPDATER AS (	
		SELECT RowNumber, NewRowNumber = ROW_NUMBER() OVER (ORDER BY RowNumber)
		FROM #Calendar)
	UPDATE UPDATER SET RowNumber = NewRowNumber

	SELECT @RowsProcessed = COUNT(*) FROM #Calendar
	SET @Msg = 'Set up for iterating over [' + CAST(@RowsProcessed AS VARCHAR(10)) + '] analysis periods'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT



	/******************************************************************************
	Load the final earnings results, adding nominee postcode district and age bucket
	******************************************************************************/
	DECLARE @MinStartDate DATE = (SELECT MIN(StartDate) FROM #Calendar)

	;WITH TranCounts AS (
		SELECT 
			t.IssuerBankAccountID,
			cal.StartDate,
			DDEarnings = SUM(CASE WHEN tt.Name LIKE '%Direct Debit%' THEN ISNULL(t.ClubCash*tt.Multiplier, 0) ELSE 0 END), 
			MobileLoginEarnings = SUM(CASE WHEN tt.Name LIKE '%Mobile%' THEN ISNULL(t.ClubCash*tt.Multiplier, 0) ELSE 0 END) 
		FROM #Calendar cal			
		INNER JOIN SLC_Report.dbo.Trans t -- Get earnings data	
			ON t.[Date] >= cal.StartDate AND CAST(t.[Date] AS date) <= cal.EndDate -- Earnings in analysis period
		INNER JOIN #RewardThreeTranTypes tt
			ON t.TypeID = tt.ID -- Get the transaction type (mobile login/non-mobile login etc.)
		WHERE t.[Date] >= @MinStartDate
		GROUP BY 
			cal.StartDate,
			t.IssuerBankAccountID
	)

	INSERT INTO Warehouse.Relational.Reward3Point0_AccountEarnings_CJM WITH (TABLOCK) 
		(
		CalculationDate, periodType, StartDate, EndDate, IsCurrentMonth
		, BankAccountID
		, PublisherID, PublisherName
		, MostRecentAccountTypeCode, MostRecentAccountType, AccountStartDate, AccountEndDate, IsJointAccount, NomineeFanID
		, Gender, AgeBucketName, PostcodeDistrict, Region

		, DDMinEarningDate
		, MobileLoginMinEarningDate
		, DDMaxEarningDate
		, MobileLoginMaxEarningDate
		, DDEarnings
		, MobileLoginEarnings
	)
	SELECT 
		@Today AS CalculationDate, c.periodType, c.StartDate, c.EndDate, CASE WHEN @Today BETWEEN c.StartDate AND c.EndDate THEN 1 ELSE 0 END AS IsCurrentMonth
		, edr.BankAccountID
		, edr.PublisherID, edr.PublisherName
		, edr.MostRecentAccountTypeCode, edr.MostRecentAccountType, edr.AccountStartDate, edr.AccountEndDate, edr.IsJointAccount, edr.NomineeFanID
		, edr.Gender, ab.BucketName AS AgeBucketName, edr.PostcodeDistrict, edr.Region

		, MIN(edr.DDMinEarningDate) AS DDMinEarningDate -- Group min/max earn dated per bank account ID
		, MIN(edr.MobileLoginMinEarningDate) AS MobileLoginMinEarningDate
		, MAX(edr.DDMaxEarningDate) AS DDMaxEarningDate
		, MAX(edr.MobileLoginMaxEarningDate) AS MobileLoginMaxEarningDate
		, ISNULL(SUM(t.DDEarnings),0)
		, ISNULL(SUM(t.MobileLoginEarnings),0)
	FROM #Calendar c
	INNER JOIN #UniqueAccountEarnDateRange edr -- Start with this table, as the results must include all customers, regardless of if they have earnt or not
		ON edr.AccountStartDate <= DATEADD(day, 3, c.EndDate) -- Accounts active in period (with an extra 3 days leeway to account for data import lag)
	LEFT JOIN #AgeBuckets ab -- Get age as of analysis period start date
		ON CAST(DATEDIFF(day, edr.DOB, c.StartDate)/365.25 AS int) BETWEEN ab.StartAge AND ab.EndAge
	LEFT JOIN TranCounts t 
		ON t.IssuerBankAccountID = edr.IssuerBankAccountID 
		AND t.StartDate = c.StartDate
	GROUP BY c.periodType, c.StartDate, c.EndDate, CASE WHEN @Today BETWEEN c.StartDate AND c.EndDate THEN 1 ELSE 0 END 
		, edr.BankAccountID
		, edr.PublisherID, edr.PublisherName
		, edr.MostRecentAccountTypeCode, edr.MostRecentAccountType, edr.AccountStartDate, edr.AccountEndDate, edr.IsJointAccount, edr.NomineeFanID
		, edr.Gender, ab.BucketName, edr.PostcodeDistrict, edr.Region;

	SET @RowsProcessed = @@ROWCOUNT;
	SET @Msg = 'Insert into Reward3Point0_AccountEarnings_CJM [' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows]'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT
	-- [50,802,672 rows] / 00:10:10

	

	/******************************************************************************
	Find BankAccounts that have closed since the last run and back populate the AccountEndDate to each row for that account
	******************************************************************************/

	DECLARE @MaxStartDate DATE = (SELECT MAX(StartDate) FROM [Relational].[Reward3Point0_AccountEarnings])	

	IF OBJECT_ID('tempdb..#NewClosures') IS NOT NULL DROP TABLE #NewClosures;
	SELECT BankAccountID
	INTO #NewClosures
	FROM Relational.Reward3Point0_AccountEarnings_CJM
	WHERE StartDate <= @MaxStartDate
	GROUP BY BankAccountID
	HAVING MAX(CASE WHEN AccountEndDate IS NULL AND StartDate < @MaxStartDate THEN 1 ELSE 0 END) = 1 
		AND MAX(CASE WHEN AccountEndDate IS NOT NULL AND StartDate = @MaxStartDate THEN 1 ELSE 0 END) = 1


	UPDATE ae
		SET AccountEndDate = (SELECT MAX(AccountEndDate) FROM Relational.Reward3Point0_AccountEarnings_CJM ae2 WHERE ae.BankAccountID = ae2.BankAccountID)
	FROM Relational.Reward3Point0_AccountEarnings_CJM ae
	INNER JOIN #NewClosures nc 
		ON nc.BankAccountID = ae.BankAccountID
	WHERE ae.AccountEndDate IS NULL;
	SET @RowsProcessed = @@ROWCOUNT;

	SET @Msg = 'Adjusted AccountEndDate [' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows]'; EXEC sp_TimerMessage @Msg, @Time OUTPUT, @SSMS OUTPUT


	/******************************************************************************
	-- QA: Check the results match the raw data in SLC_Report.dbo.Trans

	DECLARE @QAStartDate date = (SELECT (MIN(StartDate)) FROM Warehouse.Relational.Reward3Point0_AccountEarnings WHERE PeriodType = 'Month');
	DECLARE @QAEndDate date = (SELECT (MAX(EndDate)) FROM Warehouse.Relational.Reward3Point0_AccountEarnings WHERE PeriodType = 'Month');

	SELECT @QAStartDate AS QAStartDate, @QAEndDate AS QAEndDate;

	SELECT SUM(DDEarnings + MobileLoginEarnings) AS ReportEarnings FROM Warehouse.Relational.Reward3Point0_AccountEarnings 
	WHERE 
	PeriodType = 'Month'
	AND StartDate >= @QAStartDate 
	AND EndDate <= @QAEndDate;

	SELECT 
	SUM(t.ClubCash*tt.Multiplier) AS SourceDataEarnings 
	FROM SLC_Report.dbo.Trans t
	INNER JOIN SLC_Report.dbo.TransactionType tt
	ON t.TypeID = tt.ID
	WHERE 
	CAST(t.[Date] AS date) BETWEEN @QAStartDate AND @QAEndDate 
	AND t.TypeID IN (29, 31); -- 29 = direct debit earnings, 31 = mobile login earnings

	-- Slight underreporting is likely due to there being orphan IssuerBankAccountIDs in the SLC_Report.dbo.Trans table, due to an import lag
	******************************************************************************/

END

RETURN 0