-- =============================================
-- Author:		JEA
-- Create date: 01/07/2014
-- Description:	Refreshes data for retailer prospect report
-- JEA 22/02/2017 THIS REPORT HAS BEEN DECOMMISSIONED
-- Previously this procedure was run from within TotalBrandSpend_Load
-- This line has now been commented out of that procedure
-- =============================================
CREATE PROCEDURE [MI].[RetailerProspect_Refresh] 
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @BaseDate DATE, @ThisYearStart DATE, @ThisYearEnd DATE, @LastYearStart DATE, @LastYearEnd DATE, @WorkDate DATE, @BaseDatePlusYear DATE, @QuidcoRBSCardCount INT

	CREATE TABLE #Combos(ConsumerCombinationID INT PRIMARY KEY, BrandID SMALLINT NOT NULL)
	CREATE TABLE #ActiveCINS(CINID INT PRIMARY KEY)
	CREATE TABLE #CINSCore(ID INT PRIMARY KEY IDENTITY, CINID INT NOT NULL, BrandID SMALLINT NOT NULL)
	CREATE TABLE #CINSLastYear(ID INT PRIMARY KEY IDENTITY, CINID INT NOT NULL, BrandID SMALLINT NOT NULL)
	CREATE TABLE #CINSNonCore(ID INT PRIMARY KEY IDENTITY, CINID INT NOT NULL, BrandID SMALLINT NOT NULL)
	CREATE TABLE #ActiveCustomersDateActual(ActiveDate DATE PRIMARY KEY, ActiveCount INT NOT NULL)
	CREATE TABLE #ActiveCustomersMonthActual(MonthID TINYINT PRIMARY KEY, ActiveCount INT NOT NULL)
	CREATE TABLE #ActiveCustomersMonthProjected(MonthID TINYINT PRIMARY KEY, ActiveCount INT NOT NULL)
	CREATE TABLE #DateList(RunDate DATE PRIMARY KEY)
	CREATE TABLE #Quidco_Cards(PaymentCardID INT PRIMARY KEY)
	CREATE TABLE #RBSG_Cards(PaymentCardID INT PRIMARY KEY)
	CREATE TABLE #RBSG_Quidco(CINID INT PRIMARY KEY)
	CREATE TABLE #CINS_Quidco(ID INT PRIMARY KEY IDENTITY, CINID INT NOT NULL, BrandID SMALLINT NOT NULL)

	INSERT INTO MI.RetailerProspect_Audit(AuditAction)
	VALUES('ETL Started')

	SET @BaseDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	SET @ThisYearStart = DATEADD(YEAR, -1, @BaseDate)
	SET @ThisYearEnd = DATEADD(DAY, -1, @BaseDate)
	SET @LastYearStart = DATEADD(YEAR, -2, @BaseDate)
	SET @LastYearEnd = DATEADD(DAY, -1, @ThisYearStart)
	SET @BaseDatePlusYear = DATEADD(DAY, -1, DATEADD(YEAR,1, @BaseDate))

	--GATHER ACTIVE CUSTOMERS BY DATE
	SET @WorkDate = @ThisYearStart
	WHILE @WorkDate <= @BaseDate
	BEGIN

		INSERT INTO #DateList(RunDate)
		VALUES(@WorkDate)

		SET @WorkDate = DATEADD(MONTH, 1, @WorkDate)

	END

	TRUNCATE TABLE MI.RetailerProspect_ActiveCustomerMonthProjected

	--average activations for each month of the year to come
	INSERT INTO MI.RetailerProspect_ActiveCustomerMonthProjected(MonthID, ActiveCount, QuidcoCount)
	SELECT W.MonthID, W.ActiveCount, q.ActiveCount AS QuidcoCount
	FROM
	(
		SELECT MONTH(WeekStartDate) AS MonthID, AVG(ActivationForecast) AS ActiveCount
		FROM MI.CBPActivationsProjections_Weekly
		WHERE WeekStartDate BETWEEN @BaseDate AND @BaseDatePlusYear
		GROUP BY MONTH(WeekStartDate)
	) W
	INNER JOIN
	(
		SELECT MONTH(MonthDate) AS MonthID, ActiveCount
		FROM MI.RetailerProspect_QuidcoCustomerMonthlist
		WHERE MonthDate BETWEEN @BaseDate AND @BaseDatePlusYear
	) Q ON W.MonthID = Q.MonthID

	INSERT INTO MI.RetailerProspect_Audit(AuditAction)
	VALUES('Customer Counts Persisted')

	--combinations for retail brands
	INSERT INTO #Combos(ConsumerCombinationID, BrandID)
	SELECT ConsumerCombinationID, b.BrandID
	FROM Relational.ConsumerCombination C
	INNER JOIN Relational.Brand b ON c.BrandID = b.BrandID
	WHERE b.SectorID != 1
	AND b.SectorID != 2
	AND b.SectorID != 38
	AND c.IsUKSpend = 1

	--currently active CINS
	INSERT INTO #ActiveCINS(CINID)
	SELECT c.CINID
	FROM Relational.CINList c
	INNER JOIN Relational.Customer cu ON c.CIN = cu.SourceUID
	LEFT OUTER JOIN MI.CINDuplicate d ON cu.FanID =d.FanID
	WHERE cu.CurrentlyActive = 1
	AND D.FanID IS NULL

	--Get those RBSG cards that are on Quidco
	INSERT INTO #Quidco_Cards(PaymentCardID)
	SELECT DISTINCT PaymentCardID 
	FROM SLC_Report.dbo.pan 
	WHERE AffiliateID = 12 
		AND RemovalDate is null

	INSERT INTO #RBSG_Cards(PaymentCardID)
	SELECT DISTINCT PaymentCardID
	FROM SLC_Report.dbo.IssuerPaymentCard 
	WHERE [status] = 1

	INSERT INTO #RBSG_Quidco(CINID)
	SELECT CINID						
	FROM #RBSG_Cards c 
	INNER JOIN #Quidco_Cards q on c.PaymentCardID = q.PaymentCardID ---- overlap
	INNER JOIN SLC_Report.dbo.IssuerPaymentCard ipc on c.paymentcardid = ipc.PaymentCardID
	INNER JOIN SLC_Report.dbo.IssuerCustomer ic on ipc.IssuerCustomerID = ic.ID 
	INNER JOIN Relational.CINList cl on ic.sourceuid = cl.CIN
	GROUP BY CINID

	SELECT @QuidcoRBSCardCount = COUNT(1) FROM #RBSG_Quidco

	DELETE FROM MI.RetailerProspect_ActiveCustomerActual

	INSERT INTO MI.RetailerProspect_ActiveCustomerActual(ActiveCount, QuidcoCount)
	SELECT COUNT(1), @QuidcoRBSCardCount
	FROM #ActiveCINS

	INSERT INTO MI.RetailerProspect_Audit(AuditAction)
	VALUES('Combos and active CINs')

	--CINS that have spent in each brand in the last year - CORE
	INSERT INTO #CINSCore(CINID, BrandID)
	SELECT DISTINCT a.CINID, b.BrandID
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #ActiveCINS a ON ct.CINID = a.CINID
	INNER JOIN #Combos b ON CT.ConsumerCombinationID = B.ConsumerCombinationID
	WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd

	CREATE NONCLUSTERED INDEX IX_TMP_CINSCore_CINIDBrandID ON #CINSCore(CINID, BrandID)

	INSERT INTO MI.RetailerProspect_Audit(AuditAction)
	VALUES('Core CINs by brand')

	--CINS that have spent in the previous year
	INSERT INTO #CINSLastYear(CINID, BrandID)
	SELECT DISTINCT a.CINID, b.BrandID
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #ActiveCINS a ON ct.CINID = a.CINID
	INNER JOIN #Combos b ON CT.ConsumerCombinationID = B.ConsumerCombinationID
	WHERE ct.TranDate BETWEEN @LastYearStart AND @LastYearEnd

	CREATE NONCLUSTERED INDEX IX_TMP_CINSLastYear_CINIDBrandID ON #CINSLastYear(CINID, BrandID)

	INSERT INTO MI.RetailerProspect_Audit(AuditAction)
	VALUES('CINs last year')

	--CINS that have spent in the past year, excluding those that spent in the preceding year - NON-CORE
	INSERT INTO #CINSNonCore(CINID, BrandID)
	SELECT DISTINCT c.CINID, c.BrandID
	FROM #CINSCore c
	LEFT OUTER JOIN #CINSLastYear l ON c.CINID = l.CINID AND c.BrandID = l.BrandID
	WHERE l.CINID IS NULL

	DROP TABLE #CINSLastYear

	CREATE NONCLUSTERED INDEX IX_TMP_CINSNonCore_CINIDBrandID ON #CINSNonCore(CINID, BrandID)

	INSERT INTO MI.RetailerProspect_Audit(AuditAction)
	VALUES('Non-core CINS by brand')

	TRUNCATE TABLE MI.RetailerProspect_CoreSpend

	INSERT INTO MI.RetailerProspect_CoreSpend(BrandID, MonthID, Spend, Spenders)
	SELECT c.BrandID, MONTH(ct.TranDate) AS MonthID, SUM(ct.Amount) AS Spend, COUNT(DISTINCT C.CINID) AS Spenders
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #Combos co ON ct.ConsumerCombinationID = co.ConsumerCombinationID
	INNER JOIN #CINSCore c ON ct.CINID = c.CINID AND co.BrandID = c.BrandID
	WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd
	GROUP BY c.BrandID, MONTH(ct.TranDate)

	INSERT INTO MI.RetailerProspect_Audit(AuditAction)
	VALUES('Core Spend')

	TRUNCATE TABLE MI.RetailerProspect_NonCoreSpend

	INSERT INTO MI.RetailerProspect_NonCoreSpend(BrandID, MonthID, Spend, Spenders)
	SELECT c.BrandID, MONTH(ct.TranDate) AS MonthID, SUM(ct.Amount) AS Spend, COUNT(DISTINCT C.CINID) AS Spenders
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #Combos co ON ct.ConsumerCombinationID = co.ConsumerCombinationID
	INNER JOIN #CINSNonCore c ON ct.CINID = c.CINID AND co.BrandID = c.BrandID
	WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd
	GROUP BY c.BrandID, MONTH(ct.TranDate)

	INSERT INTO MI.RetailerProspect_Audit(AuditAction)
	VALUES('Non-core Spend')

	INSERT INTO #CINS_Quidco(CINID, BrandID)
	SELECT DISTINCT a.CINID, b.BrandID
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #RBSG_Quidco a ON ct.CINID = a.CINID
	INNER JOIN #Combos b ON CT.ConsumerCombinationID = B.ConsumerCombinationID
	WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd

	INSERT INTO MI.RetailerProspect_Audit(AuditAction)
	VALUES('Quidco cins and brandIDs')

	TRUNCATE TABLE MI.RetailerProspect_QuidcoSpend

	INSERT INTO MI.RetailerProspect_QuidcoSpend(BrandID, MonthID, Spend, Spenders)
	SELECT c.BrandID, MONTH(ct.TranDate) AS MonthID, SUM(ct.Amount) AS Spend, COUNT(DISTINCT C.CINID) AS Spenders
	FROM Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #Combos co ON ct.ConsumerCombinationID = co.ConsumerCombinationID
	INNER JOIN #CINS_Quidco c ON ct.CINID = c.CINID AND co.BrandID = c.BrandID
	WHERE ct.TranDate BETWEEN @ThisYearStart AND @ThisYearEnd
	AND ct.CardholderPresentData = 0
	GROUP BY c.BrandID, MONTH(ct.TranDate)

	INSERT INTO MI.RetailerProspect_Audit(AuditAction)
	VALUES('ETL Complete')

END
