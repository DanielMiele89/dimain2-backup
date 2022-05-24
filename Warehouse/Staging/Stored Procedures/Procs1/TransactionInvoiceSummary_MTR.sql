/******************************************************************************
Author: Jason Shipp
Created: 02/04/2019
Purpose:
	- Load MTR transaction data summary by month and retailer for Finance
Notes:
	- Logic relies on ONLY TWO MaskedCardNumber formats in the RAS.PANless_Transaction table: One for AMEX and one for MTR. IF THIS CHANGES, THE DATA FROM THIS QUERY WILL BE WRONG
	
------------------------------------------------------------------------------
Modification History

Jason Shipp 08/04/2019
	-- Added logic to exclude Visa transactions

Jason Shipp 15/11/2019
	-- Added extra retailer name links from SLC_Report.dbo.Partner

Jason Shipp 29/01/2020
	- Added publisher linking using SLC_REPL.dbo.CRT_File table
	- Split out MTR and HSBC results

******************************************************************************/
CREATE PROCEDURE Staging.TransactionInvoiceSummary_MTR
	
AS
BEGIN
	
	SET NOCOUNT ON;
	
	-- Load variables for calendar

	DECLARE @Today DATE = CAST(GETDATE() AS DATE);
	DECLARE @MinStartDate date = (
		SELECT CAST(MIN(TransactionDate) AS date) FROM SLC_REPL.RAS.PANless_Transaction pt
		INNER JOIN SLC_REPL.dbo.CRT_File f ON pt.FileID = f.ID
		WHERE f.MatcherShortName IN ('MTR', 'HSB')
	);
		
	-- Load minimum MTR transaction dates per PartnerID

	IF OBJECT_ID('tempdb..#MinTranDates') IS NOT NULL DROP TABLE #MinTranDates;

	SELECT 
		PartnerID
		, CAST(MIN(TransactionDate) AS date) AS MinTranDate
	INTO #MinTranDates
	FROM SLC_REPL.RAS.PANless_Transaction pt
	INNER JOIN SLC_REPL.dbo.CRT_File f 
		ON pt.FileID = f.ID
	WHERE 
		f.MatcherShortName IN ('MTR', 'HSB')
	GROUP BY
		PartnerID;

	-- Load calendar table	

	IF OBJECT_ID('tempdb..#Calendar') IS NOT NULL DROP TABLE #Calendar;

	WITH 
		E1 AS (SELECT n = 0 FROM (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) d (n))
		, E2 AS (SELECT n = 0 FROM E1 a CROSS JOIN E1 b)
		, Tally AS (SELECT n = 0 UNION ALL SELECT n = ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) FROM E2 a CROSS JOIN E2 b) -- Create table of numbers
		, TallyDates AS (SELECT n, CalDate = DATEADD(day, n, @MinStartDate) FROM Tally WHERE DATEADD(day, n, @MinStartDate) <= EOMONTH(DATEADD(day, -1, @Today))) -- Create table of consecutive dates
	SELECT DISTINCT
		m.PartnerID
		, DATEADD(day, -(DATEPART(d, CalDate)-1), CalDate) AS StartDate -- For each calendar date, minus the day of the month  
		, EOMONTH(CalDate) AS EndDate -- For each calendar date, get the end of the month 
		, 'Month' AS PeriodType
	INTO #Calendar
	FROM TallyDates t
	CROSS JOIN #MinTranDates m
	WHERE
		t.CalDate >= m.MinTranDate;

	CREATE CLUSTERED INDEX CIX_Calednar ON #Calendar (PartnerID, StartDate, EndDate);

	ALTER TABLE #Calendar ADD UNIQUE (PartnerID, StartDate, PeriodType); -- Check clendar logic hasn't been messed up

	-- Load partner alternates

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

	-- Load mapping between RetailerID and PartnerName

	IF OBJECT_ID('tempdb..#PartnerNames') IS NOT NULL DROP TABLE #PartnerNames;

	SELECT y.PartnerID, y.PartnerName 
	INTO #PartnerNames
	FROM (
		SELECT x.PartnerID, x.PartnerName, ROW_NUMBER() OVER(PARTITION BY x.PartnerID ORDER BY x.PartnerName) AS NameRank FROM (
			SELECT p.PartnerID, p.PartnerName FROM Warehouse.Relational.[Partner] p
			UNION 
			SELECT p.PartnerID, p.PartnerName FROM nFI.Relational.[Partner] p
			UNION
			SELECT p.ID AS PartnerID, p.Name AS PartnerName FROM SLC_Report.dbo.[Partner] p
		) x
	) y
	WHERE y.NameRank = 1;

	-- Load aggregated MTR transaction and invoice data 

	SELECT 
		CASE f.MatcherShortName
			WHEN 'MTR' THEN 'MTR'
			WHEN 'HSB' THEN 'HSBC'
			ELSE f.MatcherShortName
		END AS Publisher
		, pn.PartnerName AS Retailer
		, cal.StartDate AS [TranMonth]
		, SUM(pt.NetAmount) AS InvestmentExcVAT
		, SUM(pt.Price) AS Spend
		, i.InvoiceNumber
		, i.InvoiceDate
		, i.Paid
	FROM SLC_REPL.RAS.PANless_Transaction pt
	INNER JOIN #Calendar cal
		ON pt.PartnerID = cal.PartnerID
		AND CAST(pt.TransactionDate AS date) BETWEEN cal.StartDate AND cal.EndDate
	INNER JOIN SLC_REPL.dbo.CRT_File f
		ON pt.FileID = f.ID
	LEFT JOIN SLC_REPL.dbo.Invoice i
		ON pt.InvoiceID = i.ID
	LEFT JOIN #PartnerAlternate pa
		ON pt.PartnerID = pa.PartnerID
	LEFT JOIN #PartnerNames pn
		ON COALESCE(pa.AlternatePartnerID, pt.PartnerID) = pn.PartnerID
	WHERE 
		f.MatcherShortName IN ('MTR', 'HSB')
	GROUP BY
		CASE f.MatcherShortName
			WHEN 'MTR' THEN 'MTR'
			WHEN 'HSB' THEN 'HSBC'
			ELSE f.MatcherShortName
		END
		, pn.PartnerName
		, cal.StartDate
		, i.InvoiceNumber
		, i.InvoiceDate
		, i.Paid
	ORDER BY
		CASE f.MatcherShortName
			WHEN 'MTR' THEN 'MTR'
			WHEN 'HSB' THEN 'HSBC'
			ELSE f.MatcherShortName
		END
		, pn.PartnerName
		, cal.StartDate
		, i.InvoiceNumber
		, i.InvoiceDate;

END