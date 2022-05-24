-- =============================================
-- Author:		JEA
-- Create date: 05/08/2014
-- Description:	Refreshes monthly spend by CBP customers in MI.CBPTotalDebitCardUsage
-- =============================================
CREATE PROCEDURE [MI].[CBPTotalDebitCardUsage_Refresh]
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

	TRUNCATE TABLE MI.CBPTotalDebitCardUsage

	CREATE TABLE #Customers(CINID INT PRIMARY KEY, ActivatedDate DATE, DeactivatedDate DATE)
	CREATE TABLE #Combos(ConsumerCombinationID INT PRIMARY KEY)
	CREATE TABLE #Files(FileID INT PRIMARY KEY, InDate DATE NOT NULL)
	CREATE TABLE #InDate(InDate DATE PRIMARY KEY, EndDate DATE NOT NULL)
	CREATE TABLE #SpendTotals(InDate DATE PRIMARY KEY, Spend MONEY NOT NULL, CustomerCount INT NOT NULL)
	CREATE TABLE #CustomerTotals(InDate DATE PRIMARY KEY, ActiveCustomerCount INT NOT NULL)
	DECLARE @GenDate DATE, @FileEndDate DATE, @ActiveCustomerTotal INT, @SpendingCustomerTotal INT

	--Retrieve data from hardcoded scheme start to the end of the preceding month
	SET @FileEndDate = DATEADD(DAY, -1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1))

	--Include all customers, retrieving only transactions from their activation date to their deactivation or the end of the report period
	INSERT INTO #Customers(CINID, ActivatedDate, DeactivatedDate)
	SELECT cl.CINID, s.ActivatedDate, COALESCE(s.OptedOutDate, s.DeactivatedDate, @FileEndDate)
	FROM Relational.Customer c
	INNER JOIN Relational.CINList cl ON c.SourceUID = cl.CIN
	INNER JOIN MI.CustomerActiveStatus s ON c.FanID = s.FanID
	LEFT OUTER JOIN MI.CINDuplicate d ON c.FanID = d.FanID
	WHERE s.ActivatedDate <= @FileEndDate
	AND d.FanID IS NULL

	CREATE NONCLUSTERED INDEX IX_TMP_Cust_ActiveInactive ON #Customers(ActivatedDate, DeactivatedDate)

	SELECT @ActiveCustomerTotal = COUNT(1) FROM #Customers

	--record generation date - not too inefficient to do this by row because there are few of them
	SET @GenDate = GETDATE()

	--consumersector contains all retail combinations
	INSERT INTO #Combos(ConsumerCombinationID)
	SELECT ConsumerCombinationID
	FROM Relational.ConsumerSector

	--limit files queried by restricting files by in-date
	--In date recorded as the first day of the month to allow aggregation by month
	INSERT INTO #Files(FileID, InDate)
	SELECT ID, DATEFROMPARTS(YEAR(InDate), MONTH(InDate),1)
	FROM SLC_Report.dbo.NobleFiles
	WHERE FileType != 'CARDH'
	AND InDate BETWEEN '2013-08-08' AND @FileEndDate

	CREATE NONCLUSTERED INDEX IX_TMP_Files_InDate ON #Files(InDate)

	INSERT INTO #InDate(InDate, EndDate)
	SELECT DISTINCT InDate, DATEADD(DAY, -1, DATEADD(MONTH, 1, InDate)) AS EndDate
	FROM #Files
	ORDER BY InDate

	CREATE NONCLUSTERED INDEX IX_TMP_InDate_InDateEndDate ON #Indate(InDate, EndDate)

	--aggregate by month upon insertion
	INSERT INTO #SpendTotals(InDate, Spend, CustomerCount)
	SELECT f.InDate, SUM(ct.Amount) AS Spend, COUNT(DISTINCT cu.CINID) AS CustomerCount
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #Files f ON ct.FileID = f.FileID
	INNER JOIN #Customers cu ON ct.CINID = cu.CINID
	INNER JOIN #Combos co ON ct.ConsumerCombinationID = co.ConsumerCombinationID
	WHERE ct.TranDate BETWEEN cu.ActivatedDate AND cu.DeactivatedDate
	GROUP BY f.InDate

	SELECT @SpendingCustomerTotal = COUNT(DISTINCT cu.CINID)
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #Files f ON ct.FileID = f.FileID
	INNER JOIN #Customers cu ON ct.CINID = cu.CINID
	INNER JOIN #Combos co ON ct.ConsumerCombinationID = co.ConsumerCombinationID
	WHERE ct.TranDate BETWEEN cu.ActivatedDate AND cu.DeactivatedDate

	--customers who were active at any point during each month
	INSERT INTO #CustomerTotals(InDate, ActiveCustomerCount)
	SELECT i.InDate, COUNT(1) AS ActiveCustomerCount
	FROM #InDate i
	INNER JOIN #Customers c ON c.ActivatedDate <= i.EndDate AND c.DeactivatedDate >= i.InDate
	GROUP BY i.InDate

	--use #indate as the base table to ensure that all dates are present
	INSERT INTO MI.CBPTotalDebitCardUsage(GeneratedDate, MonthDate, ActiveCustomerCount, SpendingCustomerCount, Spend, ActiveCustomerTotal, SpendingCustomerTotal)
	SELECT @GenDate AS GeneratedDate
		, I.InDate AS MonthDate
		, ISNULL(c.ActiveCustomerCount, 0) AS ActiveCustomerCount
		, ISNULL(s.CustomerCount,0) AS SpendingCustomerCount
		, ISNULL(s.Spend,0) AS Spend
		, ISNULL(@ActiveCustomerTotal,0) AS ActiveCustomerTotal
		, ISNULL(@SpendingCustomerTotal,0) AS SpendingCustomerTotal
	FROM #InDate i
	LEFT OUTER JOIN #CustomerTotals c ON i.InDate = c.InDate
	LEFT OUTER JOIN #SpendTotals s ON i.InDate = s.InDate

	--drop temp tables mainly for tidyness
	DROP TABLE #Customers
	DROP TABLE #Combos
	DROP TABLE #Files
	DROP TABLE #InDate
	DROP TABLE #SpendTotals
	DROP TABLE #CustomerTotals

	EXEC msdb.dbo.sp_start_job '842C02C7-E81C-4477-A7CD-567890A61AF4'

END
