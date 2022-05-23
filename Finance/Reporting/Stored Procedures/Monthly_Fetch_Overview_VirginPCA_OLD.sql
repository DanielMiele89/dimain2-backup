﻿
CREATE PROCEDURE [Reporting].[Monthly_Fetch_Overview_VirginPCA_OLD]
(
	@MonthDate DATE = NULL
)
AS
BEGIN

	--declare @monthdate date = NULL
	SET @MonthDate = CASE 
						WHEN @MonthDate IS NULL 
							THEN GETDATE() 
						ELSE @MonthDate 
					END

	DECLARE @StartMonth DATE

	DECLARE @12Months DATE = DATEADD(DAY, 1, EOMONTH(@MonthDate, -13))
	DECLARE @EndMonth DATE = DATEADD(DAY, 1, EOMONTH(@MonthDate, -1))


	SELECT 
		@StartMonth = DATEADD(DAY, 1, EOMONTH(MIN(RegistrationDate), -1))
	FROM WH_VirginPCA.Derived.Customer
	WHERE RegistrationDate >= '2021-06-01'


	SET @StartMonth = CASE 
							WHEN @12Months > @StartMonth 
								THEN @12Months 
							ELSE @StartMonth 
						END

	--select @StartMonth, @EndMonth

	----------------------------------------------------------------------
	-- Get Participating Customers
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#Fans') IS NOT NULL DROP TABLE #Fans
	SELECT 
		cl.CINID
		, FanID
		, c.RegistrationDate
		, c.DeactivatedDate
	INTO #Fans
	FROM WH_VirginPCA.Derived.Customer c
	LEFT JOIN WH_VirginPCA.Derived.CINList cl
		ON c.SourceUID = cl.CIN
	WHERE RegistrationDate < @EndMonth -- customers that have registered since the latest date

	CREATE CLUSTERED INDEX CIX ON #Fans (CINID)
	CREATE NONCLUSTERED INDEX NCIX ON #Fans (FanID) 
	CREATE NONCLUSTERED INDEX NIX ON #Fans (RegistrationDate) INCLUDE (DeactivatedDate)
	
	
	;WITH MonthDates
	AS
	(
		SELECT
			@StartMonth AS StartDate
			, EOMONTH(@StartMonth) AS EndDate

		UNION ALL

		SELECT
			DATEADD(MONTH, 1, StartDate)
			, EOMONTH(DATEADD(MONTH, 1, StartDate))
		FROM MonthDates
		WHERE EndDate < DATEADD(MONTH, -1, @EndMonth)
	)
	SELECT
		*
	INTO #MonthDates
	FROM MonthDates

	DECLARE @KPI Reporting.KPI

	IF OBJECT_ID('tempdb..#x') IS NOT NULL
		DROP TABLE #x
	SELECT *
	INTO #x
	FROM @KPI

	INSERT INTO #x (Ordinal, KPI, KPIValue, Formatting, StartDate, EndDate)
	SELECT 
		1 AS Ordinal
		, 'Participating Customers (month end)' AS KPI
		, COUNT(1) AS KPIValue
		, 'n0' as Formatting
		, md.StartDate
		, md.EndDate 
	FROM #Fans f
	JOIN #MonthDates md
		ON f.RegistrationDate <= md.EndDate -- Registered before the end of the month
		AND COALESCE(f.DeactivatedDate, '9999-12-31') > md.EndDate -- and hasnt deactivated or deactivated after the month
	GROUP BY md.StartDate, md.EndDate
	----------------------------------------------------------------------
	-- Retail Spend by Participating Customers
	----------------------------------------------------------------------
	--INSERT INTO #x (Ordinal, KPI, KPIValue, Formatting, StartDate, EndDate)
	--SELECT 
	--	y.* 
	--	, StartDate
	--	, EndDate
	--FROM (
	--	SELECT  
	--		SUM(Amount) Amount
	--		, COUNT(1) cnt
	--		, md.startdate
	--		, md.enddate
	--	FROM WH_VirginPCA.Trans.ConsumerTransaction ct -- Get all transactions
	--	JOIN WH_VirginPCA.Trans.ConsumerCombination cc -- with the associated merchant details
	--		ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
	--	JOIN #fans f -- for our participating customers
	--		ON ct.CINID = f.CINID
	--		AND ct.TranDate >= f.registrationdate -- where transactions happened after registration
	--		AND COALESCE(f.DeactivatedDate, '9999-12-31') > ct.TranDate -- and they havent deactivated or deactivated after the trandate
	--	JOIN #MonthDates md
	--		ON ct.TranDate between md.startdate and md.enddate
	--	GROUP BY md.StartDate, md.EndDate
	--) x
	--CROSS APPLY (
	--	VALUES
	--		(2, 'Total Retail Spend by Particpating Customers', x.amount, 'c2')
	--		, (3, 'Total Retail Transactions by Particpating Customers (#)', x.cnt, 'n0')
	--) y(Ordinal, KPI, KPIValue, Formatting)

	DROP TABLE IF EXISTS #Trans
	select 
		t.TransactionID
		, f.id as fileid
		, row_number() over (partition by f.id order by t.TransactionID) rownum 
	INTO #Trans
	FROM WH_VirginPCA.inbound.Transactions t
	JOIN WH_VirginPCA.WHB.Inbound_Files f
		ON f.[FileName] = t.[FileName]

	CREATE CLUSTERED INDEX CIX ON #Trans (transactionid)

	DROP TABLE IF EXISTS #Dupes
	SELECT
		transactionid
		, MIN(FileID) FileID
	INTO #Dupes
	FROM #Trans t
	GROUP BY TransactionID 
	HAVING COUNT(1) > 1

	CREATE UNIQUE CLUSTERED INDEX CIX ON #Dupes (TransactionID)

	DROP TABLE IF EXISTS #AllTrans
	SELECT
		*
	INTO #AllTrans
	FROM #Trans t
	WHERE EXISTS (
		SELECT 1
		FROM #Dupes d
		WHERE t.TransactionID = d.TransactionID
			AND t.FileID = d.FileID
	)
		OR NOT EXISTS (
			SELECT 1
			FROM #Dupes d
			WHERE t.TransactionID = d.TransactionID
		)
	
	CREATE CLUSTERED INDEX CIX ON #AllTrans (FileID, RowNum)

	INSERT INTO #x (Ordinal, KPI, KPIValue, Formatting, StartDate, EndDate)
	SELECT 
		y.* 
		, StartDate
		, EndDate
	FROM (
		SELECT  
			SUM(Amount) Amount
			, COUNT(1) cnt
			, md.startdate
			, md.enddate
		FROM WH_VirginPCA.Trans.ConsumerTransaction ct -- Get all transactions
		JOIN WH_VirginPCA.Trans.ConsumerCombination cc -- with the associated merchant details
			ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
		JOIN #fans f -- for our participating customers
			ON ct.CINID = f.CINID
			AND ct.TranDate >= f.registrationdate -- where transactions happened after registration
			AND COALESCE(f.DeactivatedDate, '9999-12-31') > ct.TranDate -- and they havent deactivated or deactivated after the trandate
		JOIN #MonthDates md
			ON ct.TranDate between md.startdate and md.enddate
		WHERE EXISTS (
			SELECT 1
			FROM #AllTrans a
			WHERE ct.FileID = a.FileID
				and ct.RowNum = a.RowNum
		)
		GROUP BY md.StartDate, md.EndDate
	) x
	CROSS APPLY (
		VALUES
			(2, 'Total Retail Spend by Particpating Customers', x.amount, 'c2')
			, (3, 'Total Retail Transactions by Particpating Customers (#)', x.cnt, 'n0')
	) y(Ordinal, KPI, KPIValue, Formatting)

	----------------------------------------------------------------------
	-- Qualifying Spend excluding nonqualifying mccs
	----------------------------------------------------------------------
	INSERT INTO #x (Ordinal, KPI, KPIValue, Formatting, StartDate, EndDate)
	SELECT 
		y.*
		, StartDate
		, EndDate
	FROM (
		SELECT  
			SUM(Amount) Amount
			, COUNT(1) cnt
			, md.startdate
			, md.enddate
		FROM WH_VirginPCA.Trans.ConsumerTransaction ct -- Get all transactions
		JOIN WH_VirginPCA.Trans.ConsumerCombination cc -- with the associated merchant details
			ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
		JOIN #fans f -- for our participating customers
			ON ct.CINID = f.CINID
			AND ct.TranDate >= f.registrationdate -- where transactions happened after registration
			AND COALESCE(f.DeactivatedDate, '9999-12-31') > ct.TranDate -- and they havent deactivated or deactivated after the trandate
		JOIN #MonthDates md
			ON ct.TranDate between md.startdate and md.enddate
		WHERE NOT EXISTS ( -- and they are not a nonqualifying mcc
				SELECT 1
				FROM WH_VirginPCA.Trans.NonQualifyingMCCS nm -- this list was provided by the client, in consumercombination, MCCs are converted to MCCIDs
				JOIN Warehouse.Relational.MCCList mcc
					ON nm.MCC = mcc.MCC
				WHERE cc.MCCID = mcc.MCCID
			)
		AND EXISTS (
			SELECT 1
			FROM #AllTrans a
			WHERE ct.FileID = a.FileID
				and ct.RowNum = a.RowNum
		)
		GROUP BY md.StartDate, md.EndDate 
	) x
	CROSS APPLY (
		VALUES
			(4, 'Total Qualifying Retail Spend by Particpating Customers', x.amount, 'c2')
			, (5, 'Total Qualifying Retail Transactions by Particpating Customers (#)', x.cnt, 'n0')
	) y(Ordinal, KPI, KPIValue, Formatting)

	----------------------------------------------------------------------
	-- Qualifying Spend and Cashback where cashback was earned
	----------------------------------------------------------------------
	INSERT INTO #x (Ordinal, KPI, KPIValue, Formatting, StartDate, EndDate)
	SELECT 
		y.*
		, startdate
		, enddate
	FROM (
		SELECT
			SUM(TransactionAmount) Spend
			, SUM(CashbackEarned) Cashback 
			, md.StartDate
			, md.EndDate
		FROM WH_VirginPCA.Derived.PartnerTrans pt -- Matched transactions i.e. transactions from ConsumerTransaction that was incentivised and therefore a customer earned cashback
		JOIN #Fans f
			ON pt.FanID = f.FanID
		JOIN #MonthDates md
			ON pt.TransactionDate between md.StartDate and md.EndDate
			--and cashbackearned > 5000
		GROUP BY md.StartDate, md.EndDate 
	) x
	CROSS APPLY (
		VALUES
			(6, 'Retail Spend Qualifying for Cashback', x.spend, 'c2')
			, (7, 'Total Cashback Earned', x.cashback, 'c2')
	) y(Ordinal, KPI, KPIValue, Formatting)


	SELECT
		* 
	FROM #x
	ORDER BY StartDate, Ordinal


END



