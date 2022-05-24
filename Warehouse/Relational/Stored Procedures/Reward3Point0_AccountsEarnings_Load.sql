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

******************************************************************************/
CREATE PROCEDURE [Relational].[Reward3Point0_AccountsEarnings_Load] (@PublisherID int, @AnalysisStartDate date)
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Declare variables
	******************************************************************************/

	--DECLARE @PublisherID int = 132; -- For testing; 132 = Natwest, 138 = RBS etc.
	--DECLARE @AnalysisStartDate date = '2020-02-01'; -- 3.0 go live date
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
	WHERE
		c.ID = @PublisherID;

	CREATE UNIQUE CLUSTERED INDEX UCIX_IssuerPublisher ON #IssuerPublisher (PublisherID);

	DECLARE @PublisherName varchar(50) = (SELECT Name FROM #IssuerPublisher);

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
	, (81, NULL, '81+');

	CREATE UNIQUE NONCLUSTERED INDEX UNCIX_AgeBuckets ON #AgeBuckets (StartAge, EndAge);

	/******************************************************************************
	Load calendar table
	******************************************************************************/

	IF OBJECT_ID('tempdb..#Calendar') IS NOT NULL DROP TABLE #Calendar;

	WITH 
		E1 AS (SELECT n = 0 FROM (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) d (n))
		, E2 AS (SELECT n = 0 FROM E1 a CROSS JOIN E1 b)
		, Tally AS (SELECT n = 0 UNION ALL SELECT n = ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) FROM E2 a CROSS JOIN E2 b) -- Create table of numbers
		, TallyDates AS (SELECT n, CalDate = DATEADD(day, n, @AnalysisStartDate) FROM Tally WHERE DATEADD(day, n, @AnalysisStartDate) <= DATEADD(day, -1, @Today)) -- Create table of consecutive dates
		, StagingCalendar AS (
			SELECT DISTINCT
			DATEADD(day, -(DATEPART(d, CalDate)-1), CalDate) AS StartDate -- For each calendar date, minus the day of the month  
			, CASE WHEN EOMONTH(CalDate) >= @Today THEN DATEADD(day, -1, @Today) ELSE EOMONTH(CalDate) END AS EndDate -- For each calendar date, get the end of the month 
			, 'Month' AS PeriodType
			FROM TallyDates t
			WHERE
			DATEADD(day, -(DATEPART(d, CalDate)-1), CalDate) < @Today -- months starting before today
		)
		SELECT
		cal.StartDate
		, cal.EndDate
		, cal.PeriodType
		, ROW_NUMBER() OVER (ORDER BY cal.StartDate) AS RowNumber
		INTO #Calendar
		FROM StagingCalendar cal;

	CREATE  UNIQUE CLUSTERED INDEX UCIX_Calendar ON #Calendar (StartDate, EndDate);

	/******************************************************************************
	Load scheme member demographics and linked bank account type history
	******************************************************************************/

	IF OBJECT_ID('tempdb..#CustomerAccounts') IS NOT NULL DROP TABLE #CustomerAccounts;

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
	INTO #CustomerAccounts
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
	) x;
	
	CREATE NONCLUSTERED INDEX NCIX_CustomerAccounts ON #CustomerAccounts (IssuerCustomerID) INCLUDE (BankAccountID);

	/******************************************************************************
	Load account holder start, end, first and last earn dates
	******************************************************************************/

	-- Load most recent account types per IssuerBankAccountID

	IF OBJECT_ID('tempdb..#MostRecentAccountType') IS NOT NULL DROP TABLE #MostRecentAccountType;

	WITH Accounts AS (
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
	)
	SELECT DISTINCT
		a.IssuerBankAccountID
		, a.ProductCode
		, a.ProductName
	INTO #MostRecentAccountType
	FROM Accounts a
	WHERE
		(a.AccountTypeEnd = a.MaxAccountEnd OR a.AccountTypeEnd IS NULL AND a.MaxAccountEnd IS NULL);

	CREATE UNIQUE CLUSTERED INDEX UCIX_MostRecentAccountType ON #MostRecentAccountType (IssuerBankAccountID);

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
	WHERE 
		ds.MaxBankAccountNomineeStartDate = ds.StartDate
	
	CREATE UNIQUE CLUSTERED INDEX UCIX_Demographics ON #Demographics (BankAccountID);

	-- Load unique account holders

	IF OBJECT_ID('tempdb..#UniqueAccounts') IS NOT NULL DROP TABLE #UniqueAccounts;

	SELECT
		a.PublisherID
		, a.PublisherName
		, a.IssuerBankAccountID
		, a.BankAccountID
		, mra.ProductCode AS MostRecentAccountTypeCode
		, mra.ProductName AS MostRecentAccountType
		, a.IsJointAccount
		, dem.NomineeFanID
		, dem.Gender
		, dem.DOB
		, dem.Postcode
		, MIN(a.AccountTypeStart) AS AccountStartDate
		, CASE -- If IssuerBankAccountID has any NULL end dates, maintain a NULL value when using the MAX function
			WHEN MAX(CASE WHEN a.AccountTypeEnd IS NULL THEN 1 ELSE 0 END) = 0 
			THEN MAX(a.AccountTypeEnd)
			ELSE NULL
		END AS AccountEndDate
	INTO #UniqueAccounts
	FROM #CustomerAccounts a
	INNER JOIN #MostRecentAccountType mra
		ON a.IssuerBankAccountID = mra.IssuerBankAccountID
	LEFT JOIN #Demographics dem
		ON a.BankAccountID = dem.BankAccountID
	GROUP BY
		a.PublisherID
		, a.PublisherName
		, a.IssuerBankAccountID
		, a.BankAccountID
		, mra.ProductCode
		, mra.ProductName
		, a.IsJointAccount
		, dem.NomineeFanID
		, dem.Gender
		, dem.DOB
		, dem.Postcode;

	CREATE UNIQUE CLUSTERED INDEX UCIX_UniqueAccounts ON #UniqueAccounts (IssuerBankAccountID);

	-- Combine unique account holders and first/last earn dates on each account

	IF OBJECT_ID('tempdb..#UniqueAccountEarnDateRangeUnpivoted') IS NOT NULL DROP TABLE #UniqueAccountEarnDateRangeUnpivoted;

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
		, CASE 
			WHEN tt.Name LIKE ('%Direct Debit%') THEN 'DD'
			WHEN tt.Name LIKE ('%Mobile%') THEN 'MobileLogin'
			ELSE NULL
		END AS EarningType			
		, MIN(CAST(t.[Date] AS date)) AS MinEarningDate
		, MAX(CAST(t.[Date] AS date)) AS MaxEarningDate
	INTO #UniqueAccountEarnDateRangeUnpivoted
	FROM #UniqueAccounts a
	LEFT JOIN SLC_Report.dbo.Trans t
		ON a.IssuerBankAccountID = t.IssuerBankAccountID
		--AND t.FanID = c.FanID -- This condition shouldn't be needed
		AND CAST(t.[Date] AS date) >= @AnalysisStartDate
		AND t.ClubCash >0
	LEFT JOIN SLC_Report.dbo.TransactionType tt
		ON t.TypeID = tt.ID -- Get the transaction type (mobile login/non-mobile login etc.)
		AND tt.[Description] LIKE '%Reward 3.0%' -- Reward 3.0 earnings only
		AND tt.Multiplier = 1
	GROUP BY
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
		, CASE 
			WHEN tt.Name LIKE ('%Direct Debit%') THEN 'DD'
			WHEN tt.Name LIKE ('%Mobile%') THEN 'MobileLogin'
			ELSE NULL
		END;

	-- Pivot results- done separately for efficiency

	IF OBJECT_ID('tempdb..#UniqueAccountEarnDateRange') IS NOT NULL DROP TABLE #UniqueAccountEarnDateRange;

	SELECT 
		d.PublisherID
		, d.PublisherName
		, d.IssuerBankAccountID
		, d.BankAccountID
		, d.MostRecentAccountTypeCode
		, d.MostRecentAccountType
		, d.AccountStartDate
		, d.AccountEndDate
		, d.IsJointAccount
		, d.NomineeFanID
		, d.Gender
		, d.DOB
		, d.Postcode
		, MIN(CASE WHEN d.EarningType = 'DD' THEN d.MinEarningDate ELSE NULL END) AS DDMinEarningDate
		, MIN(CASE WHEN d.EarningType = 'MobileLogin' THEN d.MinEarningDate ELSE NULL END) AS MobileLoginMinEarningDate
		, MAX(CASE WHEN d.EarningType = 'DD' THEN d.MaxEarningDate ELSE NULL END) AS DDMaxEarningDate
		, MAX(CASE WHEN d.EarningType = 'MobileLogin' THEN d.MaxEarningDate ELSE NULL END) AS MobileLoginMaxEarningDate
	INTO #UniqueAccountEarnDateRange
	FROM #UniqueAccountEarnDateRangeUnpivoted d
	GROUP BY
		d.PublisherID
		, d.PublisherName
		, d.IssuerBankAccountID
		, d.BankAccountID
		, d.MostRecentAccountTypeCode
		, d.MostRecentAccountType
		, d.AccountStartDate
		, d.AccountEndDate
		, d.IsJointAccount
		, d.NomineeFanID
		, d.Gender
		, d.DOB
		, d.Postcode

	CREATE UNIQUE CLUSTERED INDEX UCIX_UniqueAccountEarnDates ON #UniqueAccountEarnDateRange (IssuerBankAccountID); -- Ensure uniqueness

	/******************************************************************************
	Load nominee history associated with bank account type history
	******************************************************************************/

	IF OBJECT_ID('tempdb..#CustomerAccountNominee') IS NOT NULL DROP TABLE #CustomerAccountNominee;

	SELECT	DISTINCT
			ca.FanID
		,	nn.IssuerCustomerID
		,	ca.PublisherID
		,	ca.PublisherName
		,	ca.IssuerBankAccountID
		,	ca.AccountTypeStart
		,	ca.AccountTypeEnd
		,	ca.ProductCode
		,	ca.ProductName
		,	CAST(nn.StartDate AS date) AS IssuerCustomerIDStart
		,	CAST(nn.EndDate AS date) AS IssuerCustomerIDEnd
	INTO #CustomerAccountNominee
	FROM #CustomerAccounts ca
	LEFT JOIN SLC_Report.dbo.DDCashbackNominee nn
		ON ca.BankAccountID = nn.BankAccountID
		AND ca.IssuerCustomerID = nn.IssuerCustomerID;

	CREATE UNIQUE CLUSTERED INDEX UCIX ON #CustomerAccountNominee (IssuerBankAccountID, AccountTypeStart, IssuerCustomerIDStart);
	CREATE NONCLUSTERED INDEX NCIX1_CustomerAccountNominee ON #CustomerAccountNominee (AccountTypeStart, AccountTypeEnd) INCLUDE (IssuerBankAccountID);
	CREATE NONCLUSTERED INDEX NCIX2_CustomerAccountNominee ON #CustomerAccountNominee (IssuerCustomerIDStart, IssuerCustomerIDEnd) INCLUDE (IssuerBankAccountID);

	/******************************************************************************
	QA: check bank account type history dates don't overlap, and check nominee dates don't overlap 
	******************************************************************************/

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

	IF @NumOverlappingDates >0 RAISERROR('Overlapping IssuerBankAccountID dates in #CustomerAccountNominee- this will create duplication errors', 16, 1);

	/******************************************************************************
	-- Create table for storing earnings results

	CREATE TABLE Warehouse.Relational.Reward3Point0_AccountEarnings (
			ID int IDENTITY (1,1)
			, CalculationDate date
			, PeriodType varchar(50) NOT NULL
			, StartDate date NOT NULL
			, EndDate date NOT NULL
			, IsCurrentMonth bit NOT NULL
			, BankAccountID int
			, PublisherID int
			, PublisherName varchar(50)
			, MostRecentAccountTypeCode varchar (20)
			, MostRecentAccountType varchar (40)
			, AccountStartDate date
			, AccountEndDate date
			, IsJointAccount bit
			, NomineeFanID int
			, Gender varchar(1)
			, AgeBucketName varchar(6)
			, PostcodeDistrict varchar(10)
			, Region varchar(30)
			, DDMinEarningDate date
			, MobileLoginMinEarningDate date
			, DDMaxEarningDate date
			, MobileLoginMaxEarningDate date
			, DDEarnings money
			, MobileLoginEarnings money
			, CONSTRAINT PK_Reward3Point0_AccountEarnings PRIMARY KEY (ID)
			, CONSTRAINT UC_Reward3Point0_AccountEarnings UNIQUE (BankAccountID, StartDate, EndDate)
	);
	CREATE NONCLUSTERED INDEX NCIX_Reward3Point0_AccountEarnings ON Warehouse.Relational.Reward3Point0_AccountEarnings (StartDate, EndDate, PublisherID) INCLUDE (BankAccountID) WITH (FILLFACTOR = 80);
	******************************************************************************/

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
	WHERE 
		(StartDate >= @RefreshFromDate) -- Delete most recent 2 months' data
		OR (StartDate <= DATEADD(month, -25, @Today)); -- Delete data over 2 years old

	DECLARE @RowNumDel int = 1;
	DECLARE @MaxRowNumDel int = (SELECT MAX(RowNumber) FROM #CalForDelete);
	DECLARE @IterPeriodDel varchar(50);
	DECLARE @IterStartDateDel date;
	DECLARE @IterEndDateDel date;

	WHILE @RowNumDel <= @MaxRowNumDel

	BEGIN

		SET @IterPeriodDel = (SELECT PeriodType FROM #CalForDelete WHERE RowNumber = @RowNumDel);
		SET @IterStartDateDel = (SELECT StartDate FROM #CalForDelete WHERE RowNumber = @RowNumDel);
		SET @IterEndDateDel = (SELECT EndDate FROM #CalForDelete WHERE RowNumber = @RowNumDel);

		DELETE FROM Warehouse.Relational.Reward3Point0_AccountEarnings 
		WHERE 
		StartDate = @IterStartDateDel
		AND EndDate <= @IterEndDateDel
		AND PublisherID = @PublisherID
		AND PeriodType = @IterPeriodDel;

		SET @RowNumDel = @RowNumDel + 1

	END

	/******************************************************************************
	Set up for iterating over analysis periods
	******************************************************************************/

	DECLARE @RowNum int = (SELECT MIN(RowNumber) FROM #Calendar);
	DECLARE @MaxRowNum int = (SELECT MAX(RowNumber) FROM #Calendar);
	DECLARE @IterPeriod varchar(50);
	DECLARE @IterStartDate date;
	DECLARE @IterEndDate date;
	DECLARE @IterStartDatePlus date;
	DECLARE @IterEndDatePlus date;

	-- Remove analysis periods associated with data deleted in results table

	DELETE FROM #Calendar
	WHERE EXISTS (
		SELECT NULL FROM Warehouse.Relational.Reward3Point0_AccountEarnings d 
		WHERE 
		#Calendar.StartDate = d.StartDate
		AND #Calendar.EndDate = d.EndDate
		AND #Calendar.PeriodType = d.PeriodType
		AND d.PublisherID = @PublisherID
	);

	-- Remove analysis periods over 2 years old

	DELETE FROM #Calendar
	WHERE StartDate <= DATEADD(month, -25, @Today)

	-- Reorder analysis periods
	
	;WITH
	UPDATER AS	(	SELECT	RowNumber
						,	NewRowNumber = ROW_NUMBER() OVER (ORDER BY RowNumber)
					FROM #Calendar)

	UPDATE UPDATER
	SET RowNumber = NewRowNumber

	-- Drop indexes for more efficient inserts

	--IF EXISTS (SELECT NULL FROM Warehouse.sys.indexes WHERE name='UC_Reward3Point0_AccountEarnings' AND object_id = OBJECT_ID('Warehouse.Relational.Reward3Point0_AccountEarnings'))
	--	ALTER TABLE Warehouse.Relational.Reward3Point0_AccountEarnings DROP CONSTRAINT UC_Reward3Point0_AccountEarnings;
	
	--ALTER INDEX NCIX_Reward3Point0_AccountEarnings ON Warehouse.Relational.Reward3Point0_AccountEarnings DISABLE;

	-- Start loop

	WHILE @RowNum <= @MaxRowNum

	BEGIN

		SET @IterStartDate = (SELECT StartDate FROM #Calendar WHERE RowNumber = @RowNum);
		SET @IterEndDate = (SELECT EndDate FROM #Calendar WHERE RowNumber = @RowNum);
		SET @IterPeriod = (SELECT PeriodType FROM #Calendar WHERE RowNumber = @RowNum);
		--SET @IterStartDatePlus = DATEADD(day, -3, @IterStartDate);
		SET @IterEndDatePlus = DATEADD(day, 3, @IterEndDate);

		/******************************************************************************
		Load transaction earnings, and link to nominee demographics and account type on the transaction date
		******************************************************************************/

		IF OBJECT_ID('tempdb..#TransactionType') IS NOT NULL DROP TABLE #TransactionType;
		SELECT *
		INTO #TransactionType
		FROM SLC_Report.dbo.TransactionType tt
		WHERE tt.[Description] LIKE '%Reward 3.0%' -- Reward 3.0 earnings only
		AND tt.Multiplier = 1 -- Exclude non-nominee earnings (these should always be 0)
		
		IF OBJECT_ID('tempdb..#TransByAccountStaging') IS NOT NULL DROP TABLE #TransByAccountStaging;

		SELECT 
			@IterStartDate AS StartDate
			, @IterEndDate AS EndDate
			, @IterPeriod AS PeriodType
			, t.IssuerBankAccountID
			, COALESCE(c.FanID, t.FanID) AS NomineeFanID
			, tt.Name AS TransactionTypeName
			, SUM(ISNULL(t.ClubCash*tt.Multiplier, 0)) AS Earnings -- If using SLC_Report.dbo.Trans as source of trans data, must always use Multiplier from tt table to account for refunds etc.
		INTO #TransByAccountStaging
		FROM SLC_Report.dbo.Trans t -- Get earnings data
		INNER JOIN #TransactionType tt
			ON t.TypeID = tt.ID -- Get the transaction type (mobile login/non-mobile login etc.)			
		INNER JOIN #UniqueAccounts ua -- Get publisher bank accounts
			ON t.IssuerBankAccountID = ua.IssuerBankAccountID
		LEFT JOIN #CustomerAccountNominee c
			ON t.IssuerBankAccountID = c.IssuerBankAccountID -- This produces duplicate data: handled in WHERE clause
			--AND t.FanID = c.FanID -- This condition shouldn't be needed
			AND CAST(t.[Date] AS date) BETWEEN c.AccountTypeStart AND COALESCE(c.AccountTypeEnd, @Today) -- Link earnings to the active account type on the transaction date. Account types in SLC are a day-behind compared to the transaction data, so small discrepancies are possible
			AND CAST(t.[Date] AS date) BETWEEN c.IssuerCustomerIDStart AND COALESCE(c.IssuerCustomerIDEnd, @Today) -- Link earnings to the nominee on the transaction date. The IssuerCustomerID associated with the transaction might not actually be for the nominee, so this must be a left join
		WHERE 
			CAST(t.[Date] AS date) BETWEEN @IterStartDate AND @IterEndDate -- Earnings in analysis period
		GROUP BY
			t.IssuerBankAccountID
			, COALESCE(c.FanID, t.FanID)
			, tt.Name;

		/******************************************************************************
		Load the final earnings results, adding nominee postcode district and age bucket
		******************************************************************************/

		INSERT INTO Warehouse.Relational.Reward3Point0_AccountEarnings (
			CalculationDate
			, periodType
			, StartDate
			, EndDate
			, IsCurrentMonth
			, BankAccountID
			, PublisherID
			, PublisherName
			, MostRecentAccountTypeCode
			, MostRecentAccountType
			, AccountStartDate
			, AccountEndDate
			, IsJointAccount
			, NomineeFanID
			, Gender
			, AgeBucketName
			, PostcodeDistrict
			, Region
			, DDMinEarningDate
			, MobileLoginMinEarningDate
			, DDMaxEarningDate
			, MobileLoginMaxEarningDate
			, DDEarnings
			, MobileLoginEarnings
		)
		SELECT 
			@Today AS CalculationDate
			, @IterPeriod AS periodType
			, @IterStartDate AS StartDate
			, @IterEndDate AS EndDate
			, CASE WHEN @Today BETWEEN @IterStartDate AND @IterEndDate THEN 1 ELSE 0 END AS IsCurrentMonth
			, edr.BankAccountID
			, edr.PublisherID
			, edr.PublisherName
			, edr.MostRecentAccountTypeCode
			, edr.MostRecentAccountType
			, edr.AccountStartDate
			, edr.AccountEndDate
			, edr.IsJointAccount
			, edr.NomineeFanID
			, edr.Gender
			, ab.BucketName AS AgeBucketName -- Age as of analysis start date
			, CASE WHEN (CHARINDEX(' ', edr.Postcode) >0) THEN LEFT(edr.Postcode, (CHARINDEX(' ', edr.Postcode)-1)) ELSE NULL END AS PostcodeDistrict
			, COALESCE(ons.Region, pa.Region) AS Region
			, MIN(edr.DDMinEarningDate) AS DDMinEarningDate -- Group min/max earn dated per bank account ID
			, MIN(edr.MobileLoginMinEarningDate) AS MobileLoginMinEarningDate
			, MAX(edr.DDMaxEarningDate) AS DDMaxEarningDate
			, MAX(edr.MobileLoginMaxEarningDate) AS MobileLoginMaxEarningDate
			, SUM(CASE WHEN t.TransactionTypeName LIKE '%Direct Debit%' THEN t.Earnings ELSE 0 END) AS DDEarnings
			, SUM(CASE WHEN t.TransactionTypeName LIKE '%Mobile%' THEN t.Earnings ELSE 0 END) AS MobileLoginEarnings
		FROM #UniqueAccountEarnDateRange edr -- Start with this table, as the results must include all customers, regardless of if they have earnt or not
		LEFT JOIN #TransByAccountStaging t
			ON edr.IssuerBankAccountID = t.IssuerBankAccountID
		LEFT JOIN Warehouse.Staging.ONSPostcodeImport ons
			ON REPLACE(edr.Postcode, ' ', '') = REPLACE(ons.Postcode, ' ', '')
		LEFT JOIN Warehouse.Relational.PostArea pa
			ON (CASE WHEN PATINDEX('%[0-9]%', edr.Postcode) >0 THEN LEFT(edr.Postcode, PATINDEX('%[0-9]%', edr.Postcode)-1) ELSE edr.Postcode END) = pa.PostAreaCode
		LEFT JOIN #AgeBuckets ab -- Get age as of analysis period start date
			ON ((CAST(DATEDIFF(day, edr.DOB, @IterStartDate)/365.25 AS int)) >= ab.StartAge OR ab.StartAge IS NULL)
			AND ((CAST(DATEDIFF(day, edr.DOB, @IterStartDate)/365.25 AS int)) <= ab.EndAge OR ab.EndAge IS NULL)
		WHERE
			edr.AccountStartDate <= @IterEndDatePlus -- Accounts active in period (with an extra 3 days leeway to account for data import lag)
			--AND (edr.AccountEndDate >= @IterStartDatePlus OR edr.AccountEndDate IS NULL) -- Leave commented out, as this causes earnings to be left out
		GROUP BY -- Aggregate by final groups (age buckets and postcodes)
			edr.BankAccountID
			, edr.PublisherID
			, edr.PublisherName
			, edr.MostRecentAccountTypeCode
			, edr.MostRecentAccountType
			, edr.AccountStartDate
			, edr.AccountEndDate
			, edr.IsJointAccount
			, edr.NomineeFanID
			, edr.Gender
			, ab.BucketName
			, CASE WHEN (CHARINDEX(' ', edr.Postcode) >0) THEN LEFT(edr.Postcode, (CHARINDEX(' ', edr.Postcode)-1)) ELSE NULL END
			, COALESCE(ons.Region, pa.Region);

		SET @RowNum = @RowNum + 1;

	END

	-- Rebuild indexes

	--IF NOT EXISTS (SELECT NULL FROM Warehouse.sys.indexes WHERE name='UC_Reward3Point0_AccountEarnings' AND object_id = OBJECT_ID('Warehouse.Relational.Reward3Point0_AccountEarnings'))
	--	ALTER TABLE Warehouse.Relational.Reward3Point0_AccountEarnings ADD CONSTRAINT UC_Reward3Point0_AccountEarnings UNIQUE (BankAccountID, StartDate, EndDate);
	
	--ALTER INDEX NCIX_Reward3Point0_AccountEarnings ON Warehouse.Relational.Reward3Point0_AccountEarnings REBUILD;


		/******************************************************************************
		Find BankAccounts that have closed since the last run and back populate the AccountEndDate to each row for that account
		******************************************************************************/

	DECLARE @MaxStartDate DATE

	SELECT @MaxStartDate = MAX(StartDate)
	FROM [Relational].[Reward3Point0_AccountEarnings]

	IF OBJECT_ID('tempdb..#AccountEndDateNull') IS NOT NULL DROP TABLE #AccountEndDateNull
	SELECT DISTINCT BankAccountID
	INTO #AccountEndDateNull
	FROM Relational.Reward3Point0_AccountEarnings
	WHERE AccountEndDate IS NULL
	AND StartDate < @MaxStartDate

	IF OBJECT_ID('tempdb..#AccountEndDateNotNull') IS NOT NULL DROP TABLE #AccountEndDateNotNull
	SELECT DISTINCT BankAccountID
	INTO #AccountEndDateNotNull
	FROM Relational.Reward3Point0_AccountEarnings
	WHERE AccountEndDate IS NOT NULL
	AND StartDate = @MaxStartDate

	UPDATE ae
	SET ae.AccountEndDate = (SELECT MAX(AccountEndDate) FROM Relational.Reward3Point0_AccountEarnings ae2 WHERE ae.BankAccountID = ae2.BankAccountID)
	FROM Relational.Reward3Point0_AccountEarnings ae
	WHERE EXISTS (SELECT 1 FROM #AccountEndDateNotNull nn WHERe ae.BankAccountID = nn.BankAccountID)
	AND EXISTS (SELECT 1 FROM #AccountEndDateNull n WHERe ae.BankAccountID = n.BankAccountID)
	AND ae.AccountEndDate IS NULL


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
