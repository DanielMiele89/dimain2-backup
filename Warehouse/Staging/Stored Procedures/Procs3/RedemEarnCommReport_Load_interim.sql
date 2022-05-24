﻿/******************************************************************************
Author: Jason Shipp
Created: 04/06/2018
Purpose:
	- Load redemption, earning, communication and online activity metrics split by Book Type and card type for MyRewards active customers
	- Data feeds Redemptions Earnings Communications Report
	- The following tables are updated:
		- Warehouse.Staging.RedemEarnCommReport_ReportData_Redemptions
		- Warehouse.Staging.RedemEarnCommReport_ReportData_Cashback
		- Warehouse.Staging.RedemEarnCommReport_ReportData_OnlineActivity
		- Warehouse.Staging.RedemEarnCommReport_ReportData_CashbackBalance

Notes:
	- Needs same access level as ProcessOp user
	
------------------------------------------------------------------------------
Modification History

Jason Shipp 16/07/2018	
	- Added summary data loads

Jason Shipp 28/08/2018	
	- Changed summary data to exclude Back Book debit card only customers

Jason Shipp 29/08/2018	
	- Optimised inserts into results tables by removing UNIONs

Jason Shipp 21/01/2019	
	- Added logic to load additional summary data by month (instead of by rolling 12-months)

Jason Shipp 25/02/2019
	- Added load of cashback balances

******************************************************************************/
CREATE PROCEDURE [Staging].[RedemEarnCommReport_Load_interim]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Declare variables
	******************************************************************************/

	DECLARE @Today date = CAST(GETDATE() AS date);
	DECLARE @RunDate DATE = DATEADD(day, -(DATEPART(day, @Today)), @Today) -- End of Last Month
	DECLARE @Months INT = 15

	/******************************************************************************
	Load date tables
	******************************************************************************/

	-- 12 Month rolling dates

	IF OBJECT_ID('tempdb..#RollingDates') IS NOT NULL DROP TABLE #RollingDates;

	WITH MonthCTE AS (
		SELECT 
			@Months AS ID
			, DATEADD(YEAR,-1,DATEADD(DAY,1,@RunDate)) AS RollingMonthStart -- Start of current month last year
			, @RunDate AS RollingMonthEnd -- End of last month
			, DATEADD(DAY,1,EOMONTH(DATEADD(MONTH,-MONTH(@RunDate),@RunDate))) AS YTDStart -- Year start of last month
			, LEFT(CONVERT(VARCHAR,@RunDate,112),6) AS YYYYMM -- Year-month of last month
		UNION ALL
		SELECT
			ID - 1 -- Increment by -1
			, DATEADD(
				DAY
				, 1
				, (EOMONTH(
					DATEADD(YEAR,-1,DATEADD(DAY,1,@RunDate))
					,-((@Months+2)-ID)
				))
			) AS RollingMonthStart -- Increment by -1 month
			, EOMONTH(DATEADD(MONTH,-((@Months+1)-ID),@RunDate)) AS RollingMonthEnd
			, DATEADD(
				DAY,1,EOMONTH(
					DATEADD(
						MONTH
						,-MONTH(DATEADD(MONTH,-((@Months+1)-ID),@RunDate))
						,DATEADD(MONTH,-((@Months+1)-ID),@RunDate)
					)
				)
			) AS YTDStart
			, LEFT(CONVERT(VARCHAR,DATEADD(MONTH,-((@Months+1)-ID),@RunDate),112),6) AS YYYYMM
		FROM MonthCTE
		WHERE 
			ID > 1 -- Terminator
	)
	SELECT *
	--, CAST(0 AS bit) AS IsYearOnYear
	INTO #RollingDates
	FROM MonthCTE
	ORDER BY ID;

	CREATE CLUSTERED INDEX combo ON #RollingDates (ID) --INCLUDE (RollingMonthStart, RollingMonthEnd, YTDStart); 

	-- Monthly dates

	IF OBJECT_ID('tempdb..#MonthDates') IS NOT NULL DROP TABLE #MonthDates;

	WITH MonthCTE AS (
		SELECT
			@Months AS ID
			, DATEADD(DAY,-DAY(@RunDate)+1,@RunDate) AS MonthStart -- Start of last month
			, @RunDate AS MonthEnd -- End of last month
			, DATEADD(DAY,1,EOMONTH(DATEADD(MONTH,-MONTH(@RunDate),@RunDate))) AS YTDStart -- Year start of last month
			, LEFT(CONVERT(VARCHAR,@RunDate,112),6) AS YYYYMM -- Year-month of last month
		UNION ALL
		SELECT	
			ID - 1 -- Increment by -1
			, DATEADD( -- Increment by -1 month
				DAY
				,-DAY(DATEADD(MONTH,-((@Months+1)-ID),@RunDate))+1
				,DATEADD(MONTH,-((@Months+1)-ID),@RunDate)
			) AS MonthStart -- Increment by -1 month
			, EOMONTH(DATEADD(MONTH,-((@Months+1)-ID),@RunDate)) AS MonthEnd
			, DATEADD(
				DAY,1,EOMONTH(
					DATEADD(
						MONTH
						,-MONTH(DATEADD(MONTH,-((@Months+1)-ID),@RunDate))
						,DATEADD(MONTH,-((@Months+1)-ID),@RunDate)
					)
				)
			) AS YTDStart
			, LEFT(CONVERT(VARCHAR,DATEADD(MONTH,-((@Months+1)-ID),@RunDate),112),6) AS YYYYMM
		FROM MonthCTE
		WHERE
			ID > 1 -- Terminator
	)
	SELECT	*
	INTO #MonthDates
	FROM MonthCTE
	ORDER BY ID;

	CREATE CLUSTERED INDEX combo ON #MonthDates (ID) --INCLUDE (MonthStart, MonthEnd, YTDStart);

	-- 3 Month rolling dates

	IF OBJECT_ID('tempdb..#QuarterDates') IS NOT NULL DROP TABLE #QuarterDates;

	WITH MonthCTE AS (
		SELECT
			@Months AS ID 
			, DATEADD(MONTH,-2,DATEADD(DAY,-DAY(@RunDate)+1,@RunDate)) AS MonthStart -- Start of month 3 months ago
			, @RunDate AS MonthEnd -- End of last month
			, DATEADD(DAY,1,EOMONTH(DATEADD(MONTH,-MONTH(@RunDate),@RunDate))) AS YTDStart -- Year start of last month
			, LEFT(CONVERT(VARCHAR,@RunDate,112),6) AS YYYYMM -- Year-month of last month
		UNION ALL
		SELECT
			ID - 1 -- Increment by -1
			, DATEADD( -- Increment by -1 month
				MONTH
				,-2
				,DATEADD(
					DAY
					,-DAY(DATEADD(MONTH,-((@Months+1)-ID),@RunDate))+1
					,DATEADD(MONTH,-((@Months+1)-ID),@RunDate))
			) AS MonthStart
			, EOMONTH(DATEADD(MONTH,-((@Months+1)-ID),@RunDate)) AS MonthEnd
			, DATEADD(
				DAY
				,1
				,EOMONTH(
					DATEADD(
						MONTH
						,-MONTH(DATEADD(MONTH,-((@Months+1)-ID),@RunDate))
						,DATEADD(MONTH,-((@Months+1)-ID),@RunDate)
					)
				)
			) AS YTDStart
			, LEFT(CONVERT(VARCHAR,DATEADD(MONTH,-((@Months+1)-ID),@RunDate),112),6) AS YYYYMM
		FROM MonthCTE
		WHERE
		 ID > 1 -- Terminator
	)
	SELECT *
	INTO #QuarterDates
	FROM MonthCTE
	ORDER BY
		ID;

	CREATE CLUSTERED INDEX cx_Stuff ON #QuarterDates (ID); 

	-- Year on year dates

	--IF OBJECT_ID('tempdb..#YearDates') IS NOT NULL DROP TABLE #YearDates;

	--; WITH YearCTE AS (
	--	SELECT
	--		2 AS ID
	--		, DATEADD(YEAR,-1,DATEADD(DAY,1,@RunDate)) AS YearStart -- Start of month 1 year ago
	--		, @RunDate AS YearEnd -- End of Last Month
	--		, LEFT(CONVERT(VARCHAR,@RunDate,112),6) AS YYYYMM -- Year-month of last month
	--UNION ALL
	--SELECT
	--	ID - 1 -- Increment by -1
	--	, DATEADD(YEAR,-(ID),DATEADD(DAY,1,@RunDate)) AS YearStart -- Increment by -1 year
	--	, EOMONTH(DATEADD(YEAR,-(ID-1),@RunDate)) AS YearEnd
	--	, LEFT(CONVERT(VARCHAR,DATEADD(YEAR,-(ID-1),@RunDate),112),6) AS YYYYMM
	--FROM YearCTE
	--WHERE
	--	1 < ID
	--)
	--SELECT *
	--INTO #YearDates
	--FROM YearCTE
	--ORDER BY
	--	ID;

	--CREATE NONCLUSTERED INDEX combo ON #YearDates (ID) INCLUDE (YearStart, YearEnd);

	-- Update IsYearOnYear in #RollingDates

	--UPDATE d
	--SET d.IsYearOnYear = 1
	--FROM #RollingDates d
	--INNER JOIN #YearDates y
	--	ON d.RollingMonthStart = y.YearStart
	--	AND d.RollingMonthEnd = y.YearEnd;

	/******************************************************************************
	Load active customers per rolling 12 month-ends
	******************************************************************************/

	IF OBJECT_ID('tempdb..#ActiveCustomersList') IS NOT NULL DROP TABLE #ActiveCustomersList;

	SELECT DISTINCT
		d.ID
		, d.RollingMonthEnd
		, c.FanID
	INTO #ActiveCustomersList
	FROM Warehouse.Relational.Customer c
	INNER JOIN #RollingDates d
		ON (d.RollingMonthEnd < c.DeactivatedDate OR c.DeactivatedDate IS NULL)
		AND (c.ActivatedDate <= d.RollingMonthEnd);

	CREATE COLUMNSTORE INDEX csx_Stuff ON #ActiveCustomersList (RollingMonthEnd, FanID, ID)

	/******************************************************************************
	Load member book types (front book / back book) and available payment methods per months
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

	CREATE CLUSTERED INDEX cix_FanID ON #BookType (FanID, Startdate);

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
	CREATE NONCLUSTERED INDEX nix_FanID_StartDate_PseudoEndDate_Value ON #BookType2 (StartDate,PseudoEndDate) INCLUDE (FanID,Value); --CJM

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

	-- Load book types per month

	IF OBJECT_ID('tempdb..#BookTypeByMonth') IS NOT NULL DROP TABLE #BookTypeByMonth;

	SELECT
		d.ID
		, c.FanID
		, c.Value
	INTO #BookTypeByMonth
	FROM #BookType2	c
	INNER JOIN #MonthDates	d
		ON (d.MonthEnd < c.PseudoEndDate OR c.PseudoEndDate IS NULL)
		AND (c.StartDate <= d.MonthEnd);

	CREATE COLUMNSTORE INDEX csx_Stuff ON #BookTypeByMonth (FanID, ID,Value )

	-- Load payment methods per months

	IF OBJECT_ID('tempdb..#CustomerPaymentMethods') IS NOT NULL DROP TABLE #CustomerPaymentMethods;

	SELECT
		d.ID
		, c.FanID
		, c.PaymentMethodsAvailableID
	INTO #CustomerPaymentMethods
	FROM Warehouse.Relational.CustomerPaymentMethodsAvailable c
	INNER JOIN #MonthDates d
		ON	c.StartDate <= d.MonthEnd
		AND	(c.EndDate IS NULL OR d.MonthEnd < c.EndDate);

	CREATE COLUMNSTORE INDEX csx_Stuff ON #CustomerPaymentMethods (PaymentMethodsAvailableID, FanID, ID)

	-- Merge rolling month results

	IF OBJECT_ID('tempdb..#SchemeMembershipLabels') IS NOT NULL DROP TABLE #SchemeMembershipLabels;

	SELECT
		a.ID
		, a.FanID
		, COALESCE(bt.Value,'B') AS Value
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
	LEFT JOIN #BookTypeByMonth bt
		ON a.ID = bt.ID
		AND a.FanID = bt.FanID
	LEFT JOIN #CustomerPaymentMethods cp 
		ON a.ID = cp.ID
		AND	a.FanID = cp.FanID;

	CREATE COLUMNSTORE INDEX csx_Stuff ON #SchemeMembershipLabels (PaymentCardMethod, PaymentMethodsAvailableID, DebitFlag, CreditFlag, Value, FanID, ID)

	-- Merge summary results

	IF OBJECT_ID('tempdb..#SummarySchemeMembershipLabels') IS NOT NULL DROP TABLE #SummarySchemeMembershipLabels;

	SELECT	
		d.ID
		, sml.FanID
	INTO #SummarySchemeMembershipLabels
	FROM #RollingDates d
	INNER JOIN	#SchemeMembershipLabels sml
		ON d.ID = sml.ID
	WHERE
		NOT (Value = 'B' AND PaymentCardMethod = 'Debit Only')
		AND PaymentCardMethod != 'None'

	CREATE COLUMNSTORE INDEX csx_Stuff ON #SummarySchemeMembershipLabels (FanID, ID)

	-- Check cardholders have not been duplicated during data wrangling

	--SELECT
	--	ID
	--	, COUNT(FanID) AS Members
	--FROM #ActiveCustomersList 
	--GROUP BY ID
	--ORDER BY ID;
	
	--SELECT
	--	ID
	--	, Value
	--	, PaymentMethodsAvailableID
	--	, DebitFlag
	--	, CreditFlag
	--	, PaymentCardMethod
	--	, COUNT(FanID) AS NumberOfCardholders
	--	, COUNT(DISTINCT FanID) AS NumberOfUniqueCardholders_ShouldMatch
	--FROM #SchemeMembershipLabels
	--GROUP BY
	--	ID
	--	, Value
	--	, PaymentMethodsAvailableID
	--	, DebitFlag
	--	, CreditFlag
	--	, PaymentCardMethod
	--ORDER BY
	--	ID
	--	, Value
	--	, PaymentMethodsAvailableID
	--	, DebitFlag
	--	, CreditFlag
	--	, PaymentCardMethod;

	/******************************************************************************
	Load redemptions
	******************************************************************************/

	-- Load redemptions per month YTD

	IF OBJECT_ID('tempdb..#YTDRedemptions') IS NOT NULL DROP TABLE #YTDRedemptions;

	SELECT
		d.ID
		, r.FanID
		, COUNT(*) AS Redemptions
	INTO #YTDRedemptions
	FROM Warehouse.Relational.Redemptions r
	INNER JOIN #RollingDates d
		ON d.YTDStart <= r.RedeemDate
		AND r.RedeemDate <= d.RollingMonthEnd
	GROUP BY
		d.ID
		, r.FanID;
	
	CREATE COLUMNSTORE INDEX csx_Stuff ON #YTDRedemptions (FanID, ID, Redemptions)

	-- Load redemptions per Rolling 12 months

	IF OBJECT_ID('tempdb..#Redemptions') IS NOT NULL DROP TABLE #Redemptions;

	-- Rolling 12 months
	SELECT
		d.ID
		, 0 AS IsSummary
		, r.FanID
		, COUNT(*) AS Redemptions
	INTO #Redemptions
	FROM Warehouse.Relational.Redemptions r
	INNER JOIN #RollingDates d
		ON d.RollingMonthStart <= r.RedeemDate
		AND r.RedeemDate <= d.RollingMonthEnd
	GROUP BY
		d.ID,
		r.FanID
	-- Rolling 12 months summary
	UNION ALL
	SELECT
		d.ID
		, 1 AS IsSummary
		, r.FanID
		, COUNT(*) AS Redemptions
	FROM Warehouse.Relational.Redemptions r
	INNER JOIN #RollingDates d
		ON d.RollingMonthStart <= r.RedeemDate
		AND r.RedeemDate <= d.RollingMonthEnd
	INNER JOIN #SummarySchemeMembershipLabels a
		ON d.ID = a.ID
		AND r.FanID = a.FanID
	GROUP BY
		d.ID
		, r.FanID
	-- Monthly summary
	UNION ALL
	SELECT
		d.ID
		, 2 AS IsSummary
		, r.FanID
		, COUNT(*) AS Redemptions
	FROM Warehouse.Relational.Redemptions r
	INNER JOIN #MonthDates d
		ON d.MonthStart <= r.RedeemDate
		AND r.RedeemDate <= d.MonthEnd
	INNER JOIN #SummarySchemeMembershipLabels a
		ON d.ID = a.ID
		AND r.FanID = a.FanID
	GROUP BY
		d.ID
		, r.FanID;

	CREATE COLUMNSTORE INDEX csx_Stuff ON #Redemptions (IsSummary, FanID, ID, Redemptions)

	-- Check for any customers who redeemed but deactivated by the date they were segmented
	--SELECT
	--	ID
	--	, COUNT(FanID) AS Members
	--FROM #Redemptions r
	--WHERE NOT EXISTS (
	--	SELECT 1
	--	FROM #SchemeMembershipLabels smt
	--	WHERE
	--		smt.ID = r.ID
	--		AND smt.FanID = r.FanID
	--)
	--GROUP BY ID
	--ORDER BY ID, Members;

	/******************************************************************************
	Load book type and redemption data
	******************************************************************************/

	-- Load active members by book type and payment method

	IF OBJECT_ID('tempdb..#ToplineActiveByBookType') IS NOT NULL DROP TABLE #ToplineActiveByBookType;

	-- Rolling 12 months
	SELECT
		smt.ID
		, 0 AS IsSummary
		, smt.Value
		, smt.PaymentMethodsAvailableID
		, smt.DebitFlag
		, smt.CreditFlag
		, smt.PaymentCardMethod
		, COUNT(smt.FanID) AS ActiveCustomers
	INTO #ToplineActiveByBookType
	FROM #SchemeMembershipLabels smt
	GROUP BY
		smt.ID
		, smt.Value
		, smt.PaymentMethodsAvailableID
		, smt.DebitFlag
		, smt.CreditFlag
		, smt.PaymentCardMethod
	-- Rolling 12 months summary
	UNION ALL
	SELECT
		smt.ID
		, 1 AS IsSummary
		, NULL AS Value
		, NULL AS PaymentMethodsAvailableID
		, NULL AS DebitFlag
		, NULL AS CreditFlag
		, NULL AS PaymentCardMethod
		, COUNT(smt.FanID) AS ActiveCustomers
	FROM #SummarySchemeMembershipLabels smt
	GROUP BY
		smt.ID
	-- Monthly summary
	UNION ALL
	SELECT
		smt.ID
		, 2 AS IsSummary
		, NULL AS Value
		, NULL AS PaymentMethodsAvailableID
		, NULL AS DebitFlag
		, NULL AS CreditFlag
		, NULL AS PaymentCardMethod
		, COUNT(smt.FanID) AS ActiveCustomers
	FROM #SummarySchemeMembershipLabels smt
	GROUP BY
		smt.ID;
	CREATE CLUSTERED INDEX cx_Stuff on #ToplineActiveByBookType (IsSummary, ID)

	-- Load active member redemptions by book type and payment method

	IF OBJECT_ID('tempdb..#RollingYearRedemptionsActiveByBookType') IS NOT NULL DROP TABLE #RollingYearRedemptionsActiveByBookType;

	-- Rolling 12 months
	SELECT	
		smt.ID
		, r.IsSummary
		, smt.Value
		, smt.PaymentMethodsAvailableID
		, smt.DebitFlag
		, smt.CreditFlag
		, smt.PaymentCardMethod
		, CASE
			WHEN r.Redemptions = 1 THEN '1'
			WHEN r.Redemptions = 2 THEN '2'
			WHEN r.Redemptions = 3 THEN '3'
			WHEN r.Redemptions = 4 THEN '4'
			ELSE '5'
		END AS RedemptionsCount
		, COUNT(r.FanID) AS RedeemersCount
	INTO #RollingYearRedemptionsActiveByBookType
	FROM #SchemeMembershipLabels smt
	INNER JOIN #Redemptions r
		ON smt.ID = r.ID
		AND	smt.FanID = r.FanID
		AND r.IsSummary = 0
	GROUP BY
		smt.ID
		, r.IsSummary
		, smt.Value
		, smt.PaymentMethodsAvailableID
		, smt.DebitFlag
		, smt.CreditFlag
		, smt.PaymentCardMethod
		, CASE
			WHEN r.Redemptions = 1 THEN '1'
			WHEN r.Redemptions = 2 THEN '2'
			WHEN r.Redemptions = 3 THEN '3'
			WHEN r.Redemptions = 4 THEN '4'
			ELSE '5'
		END
	-- Rolling 12 months summary
	UNION ALL	
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
	FROM #Redemptions r
	WHERE
		r.IsSummary = 1
	GROUP BY 
		r.ID
		, r.IsSummary
		, CASE
			WHEN r.Redemptions = 1 THEN '1'
			WHEN r.Redemptions = 2 THEN '2'
			WHEN r.Redemptions = 3 THEN '3'
			WHEN r.Redemptions = 4 THEN '4'
			ELSE '5'
		END
	-- Monthly summary
	UNION ALL	
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
	FROM #Redemptions r
	WHERE
		r.IsSummary = 2
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
	CREATE CLUSTERED INDEX cx_Stuff ON #RollingYearRedemptionsActiveByBookType (IsSummary, ID)

	-- Load active member redemptions by book type and payment method, per month YTD

	IF OBJECT_ID('tempdb..#YTDRedemptionsActiveByBookType') IS NOT NULL DROP TABLE #YTDRedemptionsActiveByBookType;

	SELECT	
		smt.ID
		, smt.Value
		, smt.PaymentMethodsAvailableID
		, smt.DebitFlag
		, smt.CreditFlag
		, smt.PaymentCardMethod
		, CASE
			WHEN ytd.Redemptions = 1 THEN '1'
			WHEN ytd.Redemptions = 2 THEN '2'
			WHEN ytd.Redemptions = 3 THEN '3'
			WHEN ytd.Redemptions = 4 THEN '4'
			ELSE '5'
		END AS RedemptionsCount
		, COUNT(ytd.FanID) AS YTDRedeemersCount
	INTO #YTDRedemptionsActiveByBookType
	FROM #SchemeMembershipLabels smt
	LEFT JOIN #YTDRedemptions ytd
		ON smt.ID = ytd.ID
		AND	smt.FanID = ytd.FanID
	GROUP BY
		smt.ID
		, smt.Value
		, smt.PaymentMethodsAvailableID
		, smt.DebitFlag
		, smt.CreditFlag
		, smt.PaymentCardMethod
		, CASE
			WHEN ytd.Redemptions = 1 THEN '1'
			WHEN ytd.Redemptions = 2 THEN '2'
			WHEN ytd.Redemptions = 3 THEN '3'
			WHEN ytd.Redemptions = 4 THEN '4'
			ELSE '5'
		END;
	CREATE COLUMNSTORE INDEX csx_Stuff ON #YTDRedemptionsActiveByBookType (PaymentCardMethod, PaymentMethodsAvailableID, DebitFlag, CreditFlag, Value, ID, RedemptionsCount, YTDRedeemersCount)

	-- Load redemption report data
	
	/******************************************************************************
	-- Create table for storing results:
	CREATE TABLE Warehouse.Staging.RedemEarnCommReport_ReportData_Redemptions (
		ID int IDENTITY(1,1) NOT NULL
		, PeriodID int NOT NULL
		, RollingMonthStart date NOT NULL
		, RollingMonthEnd date NOT NULL
		, BookTypeValue varchar(8)
		, PaymentMethodsAvailableID int
		, DebitFlag bit
		, CreditFlag bit
		, PaymentCardMethod varchar(50)
		, RedemptionsCount int
		, ActiveCustomers int
		, RedeemersCount12M int
		, YTDRedeemersCount int
		, IsSummary int NOT NULL
		, ReportDate date NOT NULL
		, CONSTRAINT PK_RedemEarnCommReport_ReportData_Redemptions PRIMARY KEY CLUSTERED (ID)
	)
	******************************************************************************/

	-- Monthly results

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
		, d.RollingMonthStart
		, d.RollingMonthEnd
		, b.Value AS BookTypeValue
		, b.PaymentMethodsAvailableID
		, b.DebitFlag
		, b.CreditFlag
		, b.PaymentCardMethod
		, b.RedemptionsCount
		, a.ActiveCustomers
		, b.RedeemersCount AS RedeemersCount12M
		, c.YTDRedeemersCount
		, 0 AS IsSummary
		, @Today AS ReportDate
	FROM #RollingDates d
	INNER JOIN #ToplineActiveByBookType a
		ON a.IsSummary = 0
		AND d.ID = a.ID
	LEFT JOIN #RollingYearRedemptionsActiveByBookType b
		ON b.IsSummary = 0
		AND a.ID = b.ID
		AND a.Value = b.Value
		AND	a.PaymentMethodsAvailableID = b.PaymentMethodsAvailableID
		AND	a.DebitFlag = b.DebitFlag
		AND	a.CreditFlag = b.CreditFlag
		AND	a.PaymentCardMethod = b.PaymentCardMethod
	LEFT JOIN #YTDRedemptionsActiveByBookType c
		ON b.ID = c.ID
		AND b.Value = c.Value
		AND	b.PaymentMethodsAvailableID = c.PaymentMethodsAvailableID
		AND	b.DebitFlag = c.DebitFlag
		AND	b.CreditFlag = c.CreditFlag
		AND	b.PaymentCardMethod = c.PaymentCardMethod
		AND	b.RedemptionsCount = c.RedemptionsCount
	WHERE 
		NOT EXISTS (
		SELECT NULL FROM Warehouse.Staging.RedemEarnCommReport_ReportData_Redemptions x
		WHERE 
			@Today = x.ReportDate
			AND d.ID = x.PeriodID
			AND d.RollingMonthStart = x.RollingMonthStart
			AND d.RollingMonthEnd = x.RollingMonthEnd
			AND (b.Value = x.BookTypeValue OR b.Value IS NULL AND x.BookTypeValue IS NULL)
			AND (b.PaymentMethodsAvailableID = x.PaymentMethodsAvailableID OR b.PaymentMethodsAvailableID IS NULL AND x.PaymentMethodsAvailableID IS NULL)
			AND (b.DebitFlag = x.DebitFlag OR b.DebitFlag IS NULL AND x.DebitFlag IS NULL)
			AND (b.CreditFlag = x.CreditFlag OR b.CreditFlag IS NULL AND x.CreditFlag IS NULL)
			AND (b.PaymentCardMethod = x.PaymentCardMethod OR b.PaymentCardMethod IS NULL AND x.PaymentCardMethod IS NULL)
			AND (b.RedemptionsCount = x.RedemptionsCount OR b.RedemptionsCount IS NULL AND x.RedemptionsCount IS NULL)
			AND x.IsSummary = 0
	)
	OPTION (RECOMPILE);

	-- Rolling month summary results TAKES THREE DAYS ChrisM

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
		, d.RollingMonthStart
		, d.RollingMonthEnd
		, b.Value AS BookTypeValue
		, b.PaymentMethodsAvailableID
		, b.DebitFlag
		, b.CreditFlag
		, b.PaymentCardMethod
		, b.RedemptionsCount
		, a.ActiveCustomers
		, b.RedeemersCount AS RedeemersCount12M
		, NULL AS YTDRedeemersCount
		, 1 AS IsSummary
		, @Today AS ReportDate
	FROM #RollingDates d
	INNER JOIN #ToplineActiveByBookType a
		ON a.IsSummary = 1
		AND d.ID = a.ID
	LEFT JOIN #RollingYearRedemptionsActiveByBookType b
		ON b.IsSummary = 1
		AND a.ID = b.ID
		AND (a.Value IS NULL AND b.Value IS NULL)
		AND	(a.PaymentMethodsAvailableID IS NULL AND b.PaymentMethodsAvailableID IS NULL)
		AND	(a.DebitFlag IS NULL AND b.DebitFlag IS NULL)
		AND	(a.CreditFlag IS NULL AND b.CreditFlag IS NULL)
		AND	(a.PaymentCardMethod IS NULL AND b.PaymentCardMethod IS NULL)
	WHERE NOT EXISTS (
		SELECT NULL FROM Warehouse.Staging.RedemEarnCommReport_ReportData_Redemptions x
		WHERE 
			@Today = x.ReportDate
			AND d.ID = x.PeriodID
			AND d.RollingMonthStart = x.RollingMonthStart
			AND d.RollingMonthEnd = x.RollingMonthEnd
			AND (b.Value IS NULL AND x.BookTypeValue IS NULL)
			AND (b.PaymentMethodsAvailableID IS NULL AND x.PaymentMethodsAvailableID IS NULL)
			AND (b.DebitFlag IS NULL AND x.DebitFlag IS NULL)
			AND (b.CreditFlag IS NULL AND x.CreditFlag IS NULL)
			AND (b.PaymentCardMethod IS NULL AND x.PaymentCardMethod IS NULL)
			AND b.RedemptionsCount = x.RedemptionsCount
			AND x.IsSummary = 1
	)
	OPTION (RECOMPILE)

	-- Monthly summary results

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
		, d.MonthStart
		, d.MonthEnd
		, b.Value AS BookTypeValue
		, b.PaymentMethodsAvailableID
		, b.DebitFlag
		, b.CreditFlag
		, b.PaymentCardMethod
		, b.RedemptionsCount
		, a.ActiveCustomers
		, b.RedeemersCount AS RedeemersCount12M
		, NULL AS YTDRedeemersCount
		, 2 AS IsSummary
		, @Today AS ReportDate
	FROM #MonthDates d
	INNER JOIN #ToplineActiveByBookType a
		ON a.IsSummary = 2
		AND d.ID = a.ID
	LEFT JOIN #RollingYearRedemptionsActiveByBookType b
		ON b.IsSummary = 2
		AND a.ID = b.ID
		AND (a.Value IS NULL AND b.Value IS NULL)
		AND	(a.PaymentMethodsAvailableID IS NULL AND b.PaymentMethodsAvailableID IS NULL)
		AND	(a.DebitFlag IS NULL AND b.DebitFlag IS NULL)
		AND	(a.CreditFlag IS NULL AND b.CreditFlag IS NULL)
		AND	(a.PaymentCardMethod IS NULL AND b.PaymentCardMethod IS NULL)
	WHERE NOT EXISTS (
		SELECT NULL FROM Warehouse.Staging.RedemEarnCommReport_ReportData_Redemptions x
		WHERE 
			@Today = x.ReportDate
			AND d.ID = x.PeriodID
			AND d.MonthStart = x.RollingMonthStart
			AND d.MonthEnd = x.RollingMonthEnd
			AND (b.Value IS NULL AND x.BookTypeValue IS NULL)
			AND (b.PaymentMethodsAvailableID IS NULL AND x.PaymentMethodsAvailableID IS NULL)
			AND (b.DebitFlag IS NULL AND x.DebitFlag IS NULL)
			AND (b.CreditFlag IS NULL AND x.CreditFlag IS NULL)
			AND (b.PaymentCardMethod IS NULL AND x.PaymentCardMethod IS NULL)
			AND b.RedemptionsCount = x.RedemptionsCount
			AND x.IsSummary = 2
	)
	OPTION (RECOMPILE);

	/******************************************************************************
	Load earnings data
	******************************************************************************/

	-- Load additional cashback award types

	IF OBJECT_ID('tempdb..#AdditionalCashbackAwardTypeID') IS NOT NULL DROP TABLE #AdditionalCashbackAwardTypeID;

	SELECT
		AdditionalCashbackAwardTypeID
		, CASE
			WHEN Title IN ('Apple Pay Adjustment','Contactless Transaction') THEN 'Credit Card'
			WHEN Title LIKE 'Credit%Card%' THEN 'Credit Card'
			ELSE 'Direct Debit'
		END AS AwardType
	INTO #AdditionalCashbackAwardTypeID
	FROM Warehouse.Relational.AdditionalCashbackAwardType;

	CREATE CLUSTERED INDEX cix_ACATID ON #AdditionalCashbackAwardTypeID (AdditionalCashbackAwardTypeID);

	-- Load customer cashback per month

	IF OBJECT_ID('tempdb..#MonthPartnerCashback') IS NOT NULL DROP TABLE #MonthPartnerCashback;

	SELECT
		ID
		, FanID
		, PaymentMethodID
		, SUM(AffiliateCommissionAmount) AS Investment
		, SUM(CashbackEarned) AS Cashback
	INTO #MonthPartnerCashback
	FROM Warehouse.Relational.PartnerTrans pt
	INNER JOIN #MonthDates d
		ON d.MonthStart <= pt.TransactionDate
		AND pt.TransactionDate <= d.MonthEnd
	GROUP BY
		ID
		,FanID
		, PaymentMethodID;

	CREATE COLUMNSTORE INDEX csx_Stuff ON #MonthPartnerCashback (PaymentMethodID, FanID, ID, Investment, Cashback)


	-- Load customer additional cashback per month
	
	IF OBJECT_ID('tempdb..#MonthPreAdditionalCashback') IS NOT NULL DROP TABLE #MonthPreAdditionalCashback;

	SELECT
		aca.AdditionalCashbackAwardTypeID
		, aca.FanID
		, d.ID
		, SUM(aca.CashbackEarned) AS Cashback
	INTO #MonthPreAdditionalCashback
	FROM Warehouse.Relational.AdditionalCashbackAward aca
	INNER JOIN #MonthDates d
		ON d.MonthStart <= aca.TranDate
		AND aca.TranDate <= d.MonthEnd
	GROUP BY
		aca.AdditionalCashbackAwardTypeID
		, aca.FanID
		, d.ID;

	CREATE COLUMNSTORE INDEX csx_Stuff ON #MonthPreAdditionalCashback (AdditionalCashbackAwardTypeID, FanID, ID, Cashback)

	-- Load customer additional cashback per month, regrouped by award type

	IF OBJECT_ID('tempdb..#MonthAdditionalCashback') IS NOT NULL DROP TABLE #MonthAdditionalCashback;

	SELECT
		ID
		, FanID
		, AwardType
		, SUM(Cashback) AS Cashback
	INTO #MonthAdditionalCashback
	FROM #MonthPreAdditionalCashback a
	INNER JOIN #AdditionalCashbackAwardTypeID acat
		ON a.AdditionalCashbackAwardTypeID = acat.AdditionalCashbackAwardTypeID
	GROUP BY
		ID
		, FanID
		, AwardType;

	CREATE COLUMNSTORE INDEX csx_Stuff ON #MonthAdditionalCashback (AwardType, FanID, ID, Cashback)


	-- Load total customer cashback per month (normal plus additional)

	IF OBJECT_ID('tempdb..#MonthCashback') IS NOT NULL DROP TABLE #MonthCashback;

	SELECT
		ID
		, FanID
		, CashbackOrigin
		, SUM(Cashback) AS Cashback
	INTO #MonthCashback
	FROM (
		SELECT
		ID
		, FanID
		, 'Retail Partner' AS CashbackOrigin
		, Cashback
		FROM #MonthPartnerCashback
		UNION ALL
		SELECT
		ID
		, FanID
		, AwardType AS CashbackOrigin
		, Cashback			
		FROM #MonthAdditionalCashback
	) a
	GROUP BY
		ID
		, FanID
		, CashbackOrigin;

	CREATE COLUMNSTORE INDEX csx_Stuff ON #MonthCashback (CashbackOrigin, FanID, ID, Cashback)


	-- Load aggregated total cashback by book type and payment method, per month

	IF OBJECT_ID('tempdb..#MonthCashbackSummary') IS NOT NULL DROP TABLE #MonthCashbackSummary;

	SELECT
		sm.ID
		, sm.Value
		, sm.PaymentMethodsAvailableID
		, sm.DebitFlag
		, sm.CreditFlag
		, sm.PaymentCardMethod
		, mcb.CashbackOrigin
		, COUNT(mcb.FanID) AS CashbackEarners
		, SUM(mcb.Cashback) AS CashbackSum
	INTO #MonthCashbackSummary
	FROM #SchemeMembershipLabels sm
	INNER JOIN #MonthCashback mcb
		ON sm.ID = mcb.ID
		AND sm.FanID = mcb.FanID
	GROUP BY
		sm.ID
		, sm.Value
		, sm.PaymentMethodsAvailableID
		, sm.DebitFlag
		, sm.CreditFlag
		, sm.PaymentCardMethod
		, mcb.CashbackOrigin;
	CREATE CLUSTERED INDEX cx_Stuff ON #MonthCashbackSummary (ID)

	-- Load cashback report data
	
	/******************************************************************************
	-- Create table for storing results:
	CREATE TABLE Warehouse.Staging.RedemEarnCommReport_ReportData_Cashback (
		ID int IDENTITY(1,1) NOT NULL
		, PeriodID int NOT NULL
		, MonthStart date NOT NULL
		, MonthEnd date NOT NULL	
		, BookTypeValue varchar(8)
		, PaymentMethodsAvailableID int
		, DebitFlag bit
		, CreditFlag bit
		, PaymentCardMethod varchar(50)
		, CashbackOrigin varchar(50)
		, ActiveCustomers int
		, MonthCashbackEarners int
		, MonthCashbackSum money
		, ReportDate date NOT NULL
		, CONSTRAINT PK_RedemEarnCommReport_ReportData_Cashback PRIMARY KEY CLUSTERED (ID)
	)
	******************************************************************************/
	
	INSERT INTO Warehouse.Staging.RedemEarnCommReport_ReportData_Cashback (
		PeriodID
		, MonthStart
		, MonthEnd
		, BookTypeValue
		, PaymentMethodsAvailableID
		, DebitFlag
		, CreditFlag
		, PaymentCardMethod
		, CashbackOrigin
		, ActiveCustomers
		, MonthCashbackEarners
		, MonthCashbackSum
		, ReportDate
	)
	SELECT
		d.ID AS PeriodID
		, d.MonthStart
		, d.MonthEnd
		, b.Value AS BookTypeValue
		, b.PaymentMethodsAvailableID
		, b.DebitFlag
		, b.CreditFlag
		, b.PaymentCardMethod
		, b.CashbackOrigin
		, a.ActiveCustomers
		, b.CashbackEarners AS MonthCashbackEarners
		, b.CashbackSum AS MonthCashbackSum
		, @Today AS ReportDate
	FROM #MonthDates d
	LEFT JOIN #MonthCashbackSummary b
		ON d.ID = b.ID
	LEFT JOIN #ToplineActiveByBookType a
		ON a.ID = b.ID
		AND	a.Value = b.Value
		AND	a.PaymentMethodsAvailableID = b.PaymentMethodsAvailableID
		AND	a.DebitFlag = b.DebitFlag
		AND	a.CreditFlag = b.CreditFlag
		AND	a.PaymentCardMethod = b.PaymentCardMethod
	WHERE NOT EXISTS (
		SELECT NULL FROM Warehouse.Staging.RedemEarnCommReport_ReportData_Cashback x
		WHERE 
			@Today = x.ReportDate
			AND d.ID = x.PeriodID
			AND d.MonthStart = x.MonthStart
			AND d.MonthEnd = x.MonthEnd
			AND (b.Value = x.BookTypeValue OR b.Value IS NULL AND x.BookTypeValue IS NULL)
			AND (b.PaymentMethodsAvailableID = x.PaymentMethodsAvailableID OR b.PaymentMethodsAvailableID IS NULL AND x.PaymentMethodsAvailableID IS NULL)
			AND (b.DebitFlag = x.DebitFlag OR b.DebitFlag IS NULL AND x.DebitFlag IS NULL)
			AND (b.CreditFlag = x.CreditFlag OR b.CreditFlag IS NULL AND x.CreditFlag IS NULL)
			AND (b.PaymentCardMethod = x.PaymentCardMethod OR b.PaymentCardMethod IS NULL AND x.PaymentCardMethod IS NULL)
			AND (b.CashbackOrigin = x.CashbackOrigin OR b.CashbackOrigin IS NULL AND x.CashbackOrigin IS NULL)
	);

	/******************************************************************************
	Load communications and online activity data
	******************************************************************************/
	
	-- Load member email marketable flag per month

	IF OBJECT_ID('tempdb..#MarketableFlag') IS NOT NULL DROP TABLE #MarketableFlag;

	SELECT DISTINCT
		d.ID
		, mkt.FanID
		, mkt.MarketableByEmail
	INTO #MarketableFlag
	FROM Warehouse.Relational.Customer_MarketableByEmailStatus mkt
	INNER JOIN #MonthDates d
		ON mkt.StartDate <= d.MonthEnd
		AND (mkt.EndDate IS NULL OR d.MonthEnd < mkt.EndDate)
	WHERE 
		mkt.MarketableByEmail = 1
	GROUP BY
		d.ID
		, mkt.FanID
		, mkt.MarketableByEmail;

	CREATE COLUMNSTORE INDEX csx_Stuff ON #MarketableFlag (MarketableByEmail, FanID, ID)

	-- Load email marketable flag per month summary

	IF OBJECT_ID('tempdb..#SummaryMarketableFlag') IS NOT NULL DROP TABLE #SummaryMarketableFlag;

	SELECT DISTINCT
		d.ID
		, mkt.FanID
		, mkt.MarketableByEmail
	INTO #SummaryMarketableFlag
	FROM Warehouse.Relational.Customer_MarketableByEmailStatus mkt
	INNER JOIN #MonthDates d
		ON	mkt.StartDate <= d.MonthEnd
		AND	(mkt.EndDate IS NULL OR d.MonthEnd < mkt.EndDate)
	INNER JOIN #SummarySchemeMembershipLabels a
		ON d.ID = a.ID
		AND mkt.FanID = a.FanID
	WHERE
		mkt.MarketableByEmail = 1
	GROUP BY
		d.ID
		, mkt.FanID
		, mkt.MarketableByEmail;

	CREATE COLUMNSTORE INDEX csx_Stuff ON #SummaryMarketableFlag (MarketableByEmail, FanID, ID)

	-- Load registered members per month

	IF OBJECT_ID('tempdb..#RegisteredCustomersList') IS NOT NULL DROP TABLE #RegisteredCustomersList;

	SELECT DISTINCT
		d.ID
		, c.FanID
		, c.Registered
	INTO #RegisteredCustomersList
	FROM Warehouse.Relational.Customer_Registered c
	INNER JOIN #MonthDates d
		ON (d.MonthEnd < c.EndDate OR c.EndDate IS NULL)
		AND (c.StartDate <= d.MonthEnd)
	WHERE
		c.Registered = 1;

	CREATE COLUMNSTORE INDEX csx_Stuff ON #RegisteredCustomersList (Registered, FanID, ID)

	-- Load registered members per month summary

	IF OBJECT_ID('tempdb..#SummaryRegisteredCustomersList') IS NOT NULL DROP TABLE #SummaryRegisteredCustomersList;

	SELECT DISTINCT
		d.ID
		, c.FanID
		, c.Registered
	INTO #SummaryRegisteredCustomersList
	FROM Warehouse.Relational.Customer_Registered c
	INNER JOIN #RollingDates d
		ON c.StartDate <= d.RollingMonthEnd
		AND	(c.EndDate IS NULL OR d.RollingMonthEnd < c.EndDate)
	INNER JOIN #SummarySchemeMembershipLabels a
		ON d.ID = a.ID
		AND c.FanID = a.FanID
	WHERE
		c.Registered = 1;

	CREATE COLUMNSTORE INDEX csx_Stuff ON #SummaryRegisteredCustomersList (Registered, FanID, ID)

	-- Load active customer registered/marketable flags by book type and payment method, per month

	IF OBJECT_ID('tempdb..#CommsTable') IS NOT NULL DROP TABLE #CommsTable;

	SELECT
		a.ID
		, a.RollingMonthEnd
		, a.FanID
		, COALESCE(m.MarketableByEmail,0) AS MarketableByEmail
		, COALESCE(r.Registered,0) AS Registered
		, sm.Value
		, sm.PaymentCardMethod
	INTO #CommsTable
	FROM #ActiveCustomersList a
	LEFT JOIN #MarketableFlag m
		ON a.ID = m.ID
		AND a.FanID = m.FanID
	LEFT JOIN
		#RegisteredCustomersList r
		ON	a.ID = r.ID
		AND a.FanID = r.FanID
	LEFT JOIN #SchemeMembershipLabels sm
		ON a.ID = sm.ID
		AND	a.FanID = sm.FanID;

	CREATE COLUMNSTORE INDEX csx_Stuff ON #CommsTable (RollingMonthEnd, PaymentCardMethod, MarketableByEmail, Registered, Value, FanID, ID)


	-- Load email opens per month

	IF OBJECT_ID('tempdb..#EmailOpens') IS NOT NULL DROP TABLE #EmailOpens;

	-- Monthly
	SELECT 
		d.ID
		, 0 AS IsSummary
		, ee.FanID 
		, COUNT(DISTINCT ee.CampaignKey) AS EmailOpens
	INTO #EmailOpens
	FROM Warehouse.Relational.EmailEvent ee -- List of Events
	INNER JOIN #MonthDates d
		ON d.MonthStart <= ee.EventDate
		AND ee.EventDate <= d.MonthEnd
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
	WHERE 
		ee.EmailEventCodeID IN (
			1301 -- Email open
			,605  -- Link click
		)
	GROUP BY 
		d.ID
		, ee.FanID
	-- Monthly summary
	UNION ALL
	SELECT 
		d.ID
		, 1 AS IsSummary
		, ee.FanID 
		, COUNT(DISTINCT ee.CampaignKey) AS EmailOpens
	FROM Warehouse.Relational.EmailEvent ee -- List of Events
	INNER JOIN #MonthDates d
		ON d.MonthStart <= ee.EventDate
		AND ee.EventDate <= d.MonthEnd
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

	CREATE COLUMNSTORE INDEX csx_Stuff on #EmailOpens (IsSummary, FanID, ID, EmailOpens)


	-- Load web logins per 3-month period

	IF OBJECT_ID('tempdb..#WebLogins3M') IS NOT NULL DROP TABLE #WebLogins3M;

	SELECT
		d.ID
		, d.MonthStart AS QuarterStart
		, d.MonthEnd AS QuarterEnd
		, wl.FanID
		, COUNT(DISTINCT CAST(TrackDate AS DATE)) AS WebLogins
	INTO #WebLogins3M
	FROM Warehouse.Relational.WebLogins wl
	INNER JOIN #QuarterDates d
		ON d.MonthStart <= wl.TrackDate
		AND wl.TrackDate <= d.MonthEnd
	GROUP BY
		d.ID
		, d.MonthStart
		, d.MonthEnd
		, wl.FanID;

	CREATE COLUMNSTORE INDEX csx_Stuff ON #WebLogins3M (FanID, QuarterEnd, QuarterStart, ID, WebLogins) 

	-- Load web logins per 12-month period

	IF OBJECT_ID('tempdb..#WebLogins12M') IS NOT NULL DROP TABLE #WebLogins12M;

	SELECT
		d.ID
		, d.RollingMonthStart
		, d.RollingMonthEnd
		, wl.FanID
		, COUNT(DISTINCT CAST(TrackDate AS DATE)) AS WebLogins
	INTO #WebLogins12M
	FROM Warehouse.Relational.WebLogins wl
	INNER JOIN #RollingDates d
		ON d.RollingMonthStart <= wl.TrackDate
		AND wl.TrackDate <= d.RollingMonthEnd
	GROUP BY
		d.ID
		, d.RollingMonthStart
		, d.RollingMonthEnd
		, wl.FanID;

	CREATE COLUMNSTORE INDEX csx_Stuff ON #WebLogins12M (FanID, RollingMonthStart, RollingMonthEnd, ID, WebLogins)

	-- Load web logins per 3-month period summary

	IF OBJECT_ID('tempdb..#SummaryWebLogins3M') IS NOT NULL DROP TABLE #SummaryWebLogins3M;
	
	SELECT
		d.ID
		, wl.FanID
		, COUNT(DISTINCT CAST(TrackDate AS DATE)) AS WebLogins
	INTO #SummaryWebLogins3M
	FROM Warehouse.Relational.WebLogins wl
	INNER JOIN #QuarterDates d
		ON d.MonthStart <= wl.TrackDate
		AND wl.TrackDate <= d.MonthEnd
	INNER JOIN #SummarySchemeMembershipLabels a
		ON d.ID = a.ID
		AND wl.FanID = a.FanID
	INNER JOIN #SummaryRegisteredCustomersList c
		ON d.ID = c.ID
		AND	wl.FanID = c.FanID
	GROUP BY 
		d.ID
		, wl.FanID;

	CREATE COLUMNSTORE INDEX csx_Stuff ON #SummaryWebLogins3M (FanID, ID, WebLogins)

	-- Load web logins per 12-month period summary

	IF OBJECT_ID('tempdb..#SummaryWebLogins12M') IS NOT NULL DROP TABLE #SummaryWebLogins12M;
	
	SELECT
		d.ID
		, wl.FanID
		, COUNT(DISTINCT CAST(TrackDate AS DATE)) AS WebLogins
	INTO #SummaryWebLogins12M
	FROM Warehouse.Relational.WebLogins wl
	INNER JOIN #RollingDates d
		ON d.RollingMonthStart <= wl.TrackDate 
		AND wl.TrackDate <= d.RollingMonthEnd
	INNER JOIN #SummarySchemeMembershipLabels a
		ON d.ID = a.ID
		AND wl.FanID = a.FanID
	INNER JOIN #SummaryRegisteredCustomersList c
		ON d.ID = c.ID
		AND	wl.FanID = c.FanID
	GROUP BY 
		d.ID
		, wl.FanID;

	CREATE COLUMNSTORE INDEX csx_Stuff ON #SummaryWebLogins12M (FanID, ID, WebLogins);

	-- Load web logins per month summary

	IF OBJECT_ID('tempdb..#SummaryWebLogins1M') IS NOT NULL DROP TABLE #SummaryWebLogins1M;
	
	SELECT
		d.ID
		, wl.FanID
		, COUNT(DISTINCT CAST(TrackDate AS DATE)) AS WebLogins
	INTO #SummaryWebLogins1M
	FROM Warehouse.Relational.WebLogins wl
	INNER JOIN #MonthDates d
		ON d.MonthStart <= wl.TrackDate
		AND wl.TrackDate <= d.MonthEnd
	INNER JOIN #SummarySchemeMembershipLabels a
		ON d.ID = a.ID
		AND wl.FanID = a.FanID
	INNER JOIN #SummaryRegisteredCustomersList c
		ON d.ID = c.ID
		AND	wl.FanID = c.FanID
	GROUP BY 
		d.ID
		, wl.FanID;

	CREATE COLUMNSTORE INDEX csx_Stuff ON #SummaryWebLogins1M (FanID, ID, WebLogins)

	/******************************************************************************
	-- Create table for storing results:
	CREATE TABLE Warehouse.Staging.RedemEarnCommReport_ReportData_OnlineActivity (
		ID int IDENTITY(1,1) NOT NULL
		, PeriodID int NOT NULL
		, YYYYMM varchar(6) NOT NULL
		, MonthStart date NOT NULL
		, MonthEnd date NOT NULL
		, BookTypeValue varchar(8)
		, PaymentCardMethod varchar(50)
		, MarketableByEmail bit
		, Registered bit
		, ActiveCustomers int
		, EmailOpeners int
		, WebsiteLogins_3M int
		, WebsiteLogins_12M int
		, IsSummary int NOT NULL
		, ReportDate date NOT NULL
		, CONSTRAINT PK_RedemEarnCommReport_ReportData_OnlineActivity PRIMARY KEY CLUSTERED (ID)
	)
	******************************************************************************/

	-- Monthly results

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
		, d.YYYYMM
		, d.MonthStart
		, d.MonthEnd
		, c.Value AS BookTypeValue
		, c.PaymentCardMethod
		, c.MarketableByEmail
		, c.Registered
		, COUNT(c.FanID) AS ActiveCustomers
		, COUNT(eo.FanID) AS EmailOpeners
		, COUNT(wl3.FanID) AS WebsiteLogins_3M
		, COUNT(wl12.FanID) AS WebsiteLogins_12M
		, 0 AS IsSummary
		, @Today AS ReportDate
	FROM #CommsTable c
	INNER JOIN #MonthDates d
		ON c.ID = d.ID
	LEFT JOIN #EmailOpens eo
		ON eo.IsSummary = 0
		AND c.ID = eo.ID
		AND	c.FanID = eo.FanID
	LEFT JOIN #WebLogins3M wl3
		ON c.ID = wl3.ID
		AND	c.FanID = wl3.FanID
	LEFT JOIN #WebLogins12M wl12
		ON c.ID = wl12.ID
		AND	c.FanID = wl12.FanID
	WHERE NOT EXISTS (
		SELECT NULL FROM Warehouse.Staging.RedemEarnCommReport_ReportData_OnlineActivity x
		WHERE 
			@Today = x.ReportDate
			AND d.ID = x.PeriodID
			AND d.MonthStart = x.MonthStart
			AND d.MonthEnd = x.MonthEnd
			AND c.Value = x.BookTypeValue
			AND c.PaymentCardMethod = x.PaymentCardMethod
			AND c.MarketableByEmail = x.MarketableByEmail
			AND c.Registered = x.Registered	
			AND x.IsSummary = 0
	)
	GROUP BY
		d.ID
		, d.YYYYMM
		, d.MonthStart
		, d.MonthEnd
		, c.Value
		, c.PaymentCardMethod
		, c.MarketableByEmail
		, c.Registered
	OPTION (RECOMPILE);
	
	-- Rolling month summary results

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
		, d.YYYYMM
		, d.MonthStart
		, d.MonthEnd
		, NULL AS BookTypeValue
		, NULL AS PaymentCardMethod
		, COALESCE(mf.MarketableByEmail,0) AS MarketableByEmail
		, COALESCE(rc.Registered,0) AS Registered
		, COUNT(c.FanID) AS ActiveCustomers
		, COUNT(eo.FanID) AS EmailOpeners
		, COUNT(wl3.FanID) AS WebsiteLogins_3M
		, COUNT(wl12.FanID) AS WebsiteLogins_12M
		, 1 AS IsSummary
		, @Today AS ReportDate
	FROM #SummarySchemeMembershipLabels c
	INNER JOIN #MonthDates d
		ON c.ID = d.ID
	LEFT JOIN #SummaryMarketableFlag mf
		ON d.ID = mf.ID
		AND c.FanID = mf.FanID
	LEFT JOIN #SummaryRegisteredCustomersList rc
		ON d.ID = rc.ID
		AND c.FanID = rc.FanID
	LEFT JOIN #EmailOpens eo
		ON eo.IsSummary = 1
		AND c.ID = eo.ID
		AND	c.FanID = eo.FanID
	LEFT JOIN #SummaryWebLogins3M wl3
		ON c.ID = wl3.ID
		AND	c.FanID = wl3.FanID
	LEFT JOIN #SummaryWebLogins12M wl12
		ON c.ID = wl12.ID
		AND	c.FanID = wl12.FanID
	WHERE NOT EXISTS (
		SELECT NULL FROM Warehouse.Staging.RedemEarnCommReport_ReportData_OnlineActivity x
		WHERE 
			@Today = x.ReportDate
			AND d.ID = x.PeriodID
			AND d.MonthStart = x.MonthStart
			AND d.MonthEnd = x.MonthEnd
			AND x.BookTypeValue IS NULL
			AND x.PaymentCardMethod IS NULL
			AND (COALESCE(mf.MarketableByEmail,0) = x.MarketableByEmail)
			AND (COALESCE(rc.Registered,0) = x.Registered)
			AND x.IsSummary = 1
	)
	GROUP BY
		d.ID
		, d.YYYYMM
		, d.MonthStart
		, d.MonthEnd
		, COALESCE(mf.MarketableByEmail,0)
		, COALESCE(rc.Registered,0)
	OPTION (RECOMPILE);

	-- Monthly summary results

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
		, d.YYYYMM
		, d.MonthStart
		, d.MonthEnd
		, NULL AS BookTypeValue
		, NULL AS PaymentCardMethod
		, COALESCE(mf.MarketableByEmail,0) AS MarketableByEmail
		, COALESCE(rc.Registered,0) AS Registered
		, COUNT(c.FanID) AS ActiveCustomers
		, COUNT(eo.FanID) AS EmailOpeners
		, COUNT(wl1.FanID) AS WebsiteLogins_3M
		, COUNT(wl1.FanID) AS WebsiteLogins_12M
		, 2 AS IsSummary
		, @Today AS ReportDate
	FROM #SummarySchemeMembershipLabels c
	INNER JOIN #MonthDates d
		ON c.ID = d.ID
	LEFT JOIN #SummaryMarketableFlag mf
		ON d.ID = mf.ID
		AND c.FanID = mf.FanID
	LEFT JOIN #SummaryRegisteredCustomersList rc
		ON d.ID = rc.ID
		AND c.FanID = rc.FanID
	LEFT JOIN #EmailOpens eo
		ON eo.IsSummary = 1
		AND c.ID = eo.ID
		AND	c.FanID = eo.FanID
	LEFT JOIN #SummaryWebLogins1M wl1
		ON c.ID = wl1.ID
		AND	c.FanID = wl1.FanID
	WHERE NOT EXISTS (
		SELECT NULL FROM Warehouse.Staging.RedemEarnCommReport_ReportData_OnlineActivity x
		WHERE 
			@Today = x.ReportDate
			AND d.ID = x.PeriodID
			AND d.MonthStart = x.MonthStart
			AND d.MonthEnd = x.MonthEnd
			AND x.BookTypeValue IS NULL
			AND x.PaymentCardMethod IS NULL
			AND (COALESCE(mf.MarketableByEmail,0) = x.MarketableByEmail)
			AND (COALESCE(rc.Registered,0) = x.Registered)
			AND x.IsSummary = 2
	)
	GROUP BY
		d.ID
		, d.YYYYMM
		, d.MonthStart
		, d.MonthEnd
		, COALESCE(mf.MarketableByEmail,0)
		, COALESCE(rc.Registered,0)
	OPTION (RECOMPILE);

	/******************************************************************************
	-- Load cashback balances
	
	-- Create table for storing results:

	CREATE TABLE Warehouse.Staging.RedemEarnCommReport_ReportData_CashbackBalance (
		ID int IDENTITY(1,1) NOT NULL
		, PeriodID int NOT NULL
		, MonthEnd date NOT NULL
		, PaymentCardMethod varchar(50) NOT NULL
		, Registered bit NOT NULL
		, Accounts int
		, ClubCashPending money
		, ReportDate date
		, CONSTRAINT PK_RedemEarnCommReport_ReportData_CashbackBalance PRIMARY KEY CLUSTERED (ID)
	)	
	******************************************************************************/

	INSERT INTO Warehouse.Staging.RedemEarnCommReport_ReportData_CashbackBalance (
		PeriodID
		, MonthEnd
		, PaymentCardMethod
		, Registered
		, Accounts
		, ClubCashPending
		, ReportDate
	)
	SELECT
		d.ID AS PeriodID
		, d.MonthEnd
		, l.PaymentCardMethod
		, COALESCE(r.Registered,0) AS Registered
		, COUNT(b.FanID) AS Accounts
		, SUM(b.ClubcashPending) AS ClubCashPending
		, @Today AS ReportDate
	FROM #MonthDates d
	INNER JOIN #ActiveCustomersList a
		ON d.ID = a.ID
	LEFT JOIN #RegisteredCustomersList r
		ON d.ID = r.ID
		AND a.FanID = r.FanID
	LEFT JOIN #SchemeMembershipLabels l
		ON d.ID = l.ID
		AND a.FanID = l.FanID
	LEFT JOIN Warehouse.Staging.Customer_CashbackBalances b
		ON d.MonthEnd = b.[Date]
		AND a.FanID = b.FanID
	LEFT JOIN Warehouse.MI.CINDuplicate x
		ON a.FanID = x.FanID
	WHERE 
		x.FanID IS NULL
		AND NOT EXISTS (
			SELECT NULL FROM Warehouse.Staging.RedemEarnCommReport_ReportData_CashbackBalance rd
			WHERE 
			d.ID = rd.PeriodID
			AND d.MonthEnd = rd.MonthEnd
			AND l.PaymentCardMethod = rd.PaymentCardMethod
			AND COALESCE(r.Registered,0) = rd.Registered	
			AND rd.ReportDate = @Today
		)
	GROUP BY
		d.ID	
		, d.MonthEnd
		, l.PaymentCardMethod
		, r.Registered;

END