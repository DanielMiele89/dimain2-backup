CREATE PROCEDURE [gas].[TotalBrandSpend_Refresh]
AS
BEGIN

SET NOCOUNT ON

	DECLARE @ProcessStart SMALLDATETIME, @ProcessEnd SMALLDATETIME

	--use this rather than WITH ROLLUP because it is much quicker on the CardTransaction dataset
	DECLARE @CustomerCount INT

	SET @ProcessStart = GETDATE()

	TRUNCATE TABLE Relational.TotalBrandSpend
	TRUNCATE TABLE Relational.TotalBrandSpendOnline
	
	DECLARE @StartDate Date, @EndDate Date
	
	--first day of the current month
	SET @EndDate = CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(GETDATE())-1),GETDATE()),101)
	--previous year
	SET @StartDate = DATEADD(YEAR, -1, @EndDate)
	--last day of that year
	SET @EndDate = DATEADD(DAY, -1, @EndDate)
	
	CREATE TABLE #BrandMIDs(BrandMIDID int not null, BrandID SmallInt not null)
	INSERT INTO #BrandMIDs(BrandMIDID, BrandID)
	SELECT BrandMIDID, BrandID
	FROM Relational.BrandMID
	WHERE BrandID != 944

	ALTER TABLE #BrandMIDs ADD PRIMARY KEY(BrandMIDID)

	--INSERT TOTAL SPEND FIGURES
	INSERT INTO Relational.TotalBrandSpend(BrandID, Amount, CustomerCount, TransCount)
	SELECT b.brandid, SUM(amount) AS Amount, COUNT(distinct c.cinid) as CustomerCount, COUNT(1) as TransCount
	FROM Relational.CardTransaction c WITH (NOLOCK)
	INNER JOIN #BrandMIDs b on c.BrandMIDID = b.BrandMIDID
	LEFT OUTER JOIN Relational.CINOptOutList o on c.CINID = o.CINID
	WHERE C.TranDate BETWEEN @StartDate AND @EndDate
	AND O.CINID IS NULL
	GROUP BY B.BrandID
	
	SELECT @CustomerCount = COUNT(DISTINCT c.CINID)
	FROM Relational.CardTransaction c WITH (NOLOCK)
	INNER JOIN #BrandMIDs b on c.BrandMIDID = b. BrandMIDID
	LEFT OUTER JOIN Relational.CINOptOutList o on c.CINID = o.CINID
	WHERE C.TranDate BETWEEN @StartDate AND @EndDate
	AND O.CINID IS NULL
	
	INSERT INTO Relational.TotalBrandSpend(brandid, Amount, CustomerCount, TransCount)
	SELECT 0, SUM(Amount), @CustomerCount, SUM(transcount)
	FROM Relational.TotalBrandSpend
	
	INSERT INTO Relational.TotalBrandSpendArchive(StartDate
		, EndDate
		, BrandID
		, Amount
		, CustomerCount
		, TransCount)
		
	SELECT @StartDate
		, @EndDate
		, BrandID
		, Amount
		, CustomerCount
		, TransCount
	FROM Relational.TotalBrandSpend

	--INSERT ONLINE SPEND FIGURES
	INSERT INTO Relational.TotalBrandSpendOnline(BrandID, Amount, CustomerCount, TransCount)
	SELECT b.brandid, SUM(amount) AS Amount, COUNT(distinct c.cinid) as CustomerCount, COUNT(1) as TransCount
	FROM Relational.CardTransaction c WITH (NOLOCK)
	INNER JOIN #BrandMIDs b on c.BrandMIDID = b.BrandMIDID
	LEFT OUTER JOIN Relational.CINOptOutList o on c.CINID = o.CINID
	WHERE C.TranDate BETWEEN @StartDate AND @EndDate
	AND O.CINID IS NULL
	AND C.CardholderPresentData = '5'
	GROUP BY B.BrandID
	
	SELECT @CustomerCount = COUNT(DISTINCT c.CINID)
	FROM Relational.CardTransaction c WITH (NOLOCK)
	INNER JOIN #BrandMIDs b on c.BrandMIDID = b. BrandMIDID
	LEFT OUTER JOIN Relational.CINOptOutList o on c.CINID = o.CINID
	WHERE C.TranDate BETWEEN @StartDate AND @EndDate
	AND O.CINID IS NULL
	AND C.CardholderPresentData = '5'
	
	INSERT INTO Relational.TotalBrandSpendOnline(brandid, Amount, CustomerCount, TransCount)
	SELECT 0, SUM(Amount), @CustomerCount, SUM(transcount)
	FROM Relational.TotalBrandSpend
	
	INSERT INTO Relational.TotalBrandSpendOnlineArchive(StartDate
		, EndDate
		, BrandID
		, Amount
		, CustomerCount
		, TransCount)
		
	SELECT @StartDate
		, @EndDate
		, BrandID
		, Amount
		, CustomerCount
		, TransCount
	FROM Relational.TotalBrandSpendOnline
	
	SET @ProcessEnd = GETDATE()
	
	UPDATE Staging.TotalBrandSpendAudit
	SET ProcessStart = @ProcessStart
		, ProcessEnd = @ProcessEnd

END