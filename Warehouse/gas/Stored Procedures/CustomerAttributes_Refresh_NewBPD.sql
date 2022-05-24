
-- =============================================
-- Author:		JEA
-- Create date: 29/11/2012
-- Description:	Refreshes customer attributes
-- =============================================
CREATE PROCEDURE [gas].[CustomerAttributes_Refresh_NewBPD]
	--WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @MaxFileDate DATE, @MinFileDate DATE, @SixMonthsEarlier DATE, @ThreeMonthsEarlier DATE
	SET @MaxFileDate = DATEADD(day, -7, getdate())
	
	--first day of the current month
	SET @MaxFileDate = CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(GETDATE())-1),GETDATE()),101)
	--previous year
	SET @MinFileDate = DATEADD(YEAR, -1, @MaxFileDate)
	--last day of that year
	SET @MaxFileDate = DATEADD(DAY, -1, @MaxFileDate)
	SET @SixMonthsEarlier = DATEADD(MONTH, -6, @MaxFileDate)
	SET @ThreeMonthsEarlier = DATEADD(MONTH, -3, @MaxFileDate)

    INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES('Start Refresh')

	EXEC MI.USPFigures_Refresh

	INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES('USP Figures Generated')

	ALTER INDEX IX_CustomerAttribute_FrequencyYearRetail ON Relational.CustomerAttribute DISABLE
	ALTER INDEX IX_CustomerAttribute_ValueYearRetail ON Relational.CustomerAttribute DISABLE
	ALTER INDEX IX_CustomerAttribute_FirstTranDate ON Relational.CustomerAttribute DISABLE
	ALTER INDEX IX_CustomerAttribute_BankIDFirstTranDate ON Relational.CustomerAttribute DISABLE

	INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES('Disable Indexes')
	
	--CONSUMERSECTOR REFRESH SECTION BEGINS
	
	ALTER INDEX IX_Relational_ConsumerSector_BrandSector ON Relational.ConsumerSector DISABLE
	
	TRUNCATE TABLE Relational.ConsumerSector

	INSERT INTO Relational.ConsumerSector(ConsumerCombinationID, BrandID, SectorID)
	SELECT c.ConsumerCombinationID, b.BrandID, b.SectorID
	FROM Relational.ConsumerCombination c
	INNER JOIN Relational.Brand b ON c.BrandID = b.BrandID
	WHERE b.BrandID != 944
	AND b.SectorID > 2
	AND b.SectorID != 38

	UNION

	SELECT c.ConsumerCombinationID, 944, M.SectorID
	FROM Relational.ConsumerCombination c
	INNER JOIN Relational.MCCList M ON c.MCCID = M.MCCID
	WHERE c.BrandID = 944
	AND c.IsUKSpend = 1
	AND m.SectorID > 2
	AND m.SectorID != 38

	ALTER INDEX IX_Relational_ConsumerSector_BrandSector ON Relational.ConsumerSector REBUILD
	
	INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES('Refresh ConsumerSector')
	
	--BRANDMIDSECTOR REFRESH SECTION ENDS

	INSERT INTO Relational.CustomerAttribute(CINID)
	SELECT CINID
	FROM Relational.CINList
	EXCEPT
	SELECT CINID
	FROM Relational.CustomerAttribute
	
	INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES('Add New CINIDs')

	UPDATE Relational.CustomerAttribute SET OutdoorHiking = 0
		, Parent = 0
		, ParentOfYoung = 0
		, Gambling = 0
		, Pets = 0
		, OnlineGroceriesRegular = 0
		, OnlineGroceriesTentative = 0
		, OnlineOnly = 0
		, OnlineAndOffline = 0
		, OfflineOnly = 0
		, NotShopped = 0
		, RecencyOnline = null
		, RecencyOffline = null
		, RecencyCoalition = null
		, RecencyNonCoalition = null
		, FirstTranDate = null
		, VisitsOnline = 0
		, VisitsOffline = 0
		, VisitsCoalition = 0
		, VisitsNonCoalition = 0
		, CarOwner = 0
		, ValueMonthTotal = 0
		, ValueMonthOnline = 0
		, ValueMonthCoalition = 0
		, FrequencyMonthTotal = 0
		, FrequencyMonthOnline = 0
		, FrequencyMonthCoalition = 0
		, FrequencyYearRetail = 0
		, ValueYearRetail = 0
		, RecencyYearRetailDays = NULL
		, BankID = 2  --default NatWest

	INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES('Clear Values')

	CREATE TABLE #ParentCombos(ConsumerCombinationID INT NOT NULL)
	
	INSERT INTO #ParentCombos(ConsumerCombinationID)
	
	SELECT ConsumerCombinationID
	FROM Relational.ConsumerCombination c
	INNER JOIN MI.CustomerAttributeBrand b ON c.BrandID = b.BrandID
	WHERE b.AttributeType = 1
	
	UNION

	SELECT ConsumerCombinationID
	FROM Relational.ConsumerCombination c
	INNER JOIN MI.CustomerAttributeMCC m ON c.MCCID = m.MCCID
	WHERE m.AttributeType = 1

	ALTER TABLE #ParentCombos ADD PRIMARY KEY(ConsumerCombinationID)

	UPDATE Relational.CustomerAttribute SET Parent = 1
	FROM Relational.CustomerAttribute c
	INNER JOIN 
	(
		SELECT c.CINID, COUNT(1) AS Frequency	
		FROM Relational.ConsumerTransaction c WITH (NOLOCK)
		INNER JOIN #ParentCombos p WITH (NOLOCK) on c.ConsumerCombinationID = p.ConsumerCombinationID	
		WHERE C.TranDate BETWEEN @SixMonthsEarlier AND @MaxFileDate	
		GROUP BY c.CINID	
		HAVING COUNT(1) >= 2
	) o ON c.CINID = o.CINID

	DROP TABLE #ParentCombos

	INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES('Parent')

	CREATE TABLE #YoungParentCombos(ConsumerCombinationID INT NOT NULL)
	
	INSERT INTO #YoungParentCombos(ConsumerCombinationID)
	
	SELECT ConsumerCombinationID
	FROM Relational.ConsumerCombination c
	INNER JOIN MI.CustomerAttributeBrand b ON c.BrandID = b.BrandID
	WHERE b.AttributeType = 2
	
	UNION

	SELECT ConsumerCombinationID
	FROM Relational.ConsumerCombination c
	INNER JOIN MI.CustomerAttributeMCC m ON c.MCCID = m.MCCID
	WHERE m.AttributeType = 2

	ALTER TABLE #YoungParentCombos ADD PRIMARY KEY(ConsumerCombinationID)

	UPDATE Relational.CustomerAttribute SET ParentOfYoung = 1
	FROM Relational.CustomerAttribute c
	INNER JOIN 
	(
		SELECT c.CINID, COUNT(1) AS Frequency	
		FROM Relational.ConsumerTransaction c WITH (NOLOCK)
		INNER JOIN #YoungParentCombo y WITH (NOLOCK) on c.ConsumerCombinationID = y.ConsumerCombinationID
		WHERE C.TranDate BETWEEN @SixMonthsEarlier AND @MaxFileDate	
		GROUP BY c.CINID	
		HAVING COUNT(1) >= 2
	) o on c.CINID = o.CINID	

	INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES('ParentOfYoung')

	DROP TABLE #YoungParentCombos

	CREATE TABLE #PetCombos(ConsumerCombinationID INT NOT NULL)
	
	INSERT INTO #PetCombos(ConsumerCombinationID)
	
	SELECT ConsumerCombinationID
	FROM Relational.ConsumerCombination c
	INNER JOIN MI.CustomerAttributeBrand b ON c.BrandID = b.BrandID
	WHERE b.AttributeType = 3
	
	UNION

	SELECT ConsumerCombinationID
	FROM Relational.ConsumerCombination c
	INNER JOIN MI.CustomerAttributeMCC m ON c.MCCID = m.MCCID
	WHERE m.AttributeType = 3

	ALTER TABLE #PetCombos ADD PRIMARY KEY(ConsumerCombinationID)

	UPDATE Relational.CustomerAttribute SET Pets = 1
	FROM Relational.CustomerAttribute c
	INNER JOIN 
	(
		SELECT c.CINID, COUNT(1) AS Frequency			
		FROM Relational.CardTransaction c WITH (NOLOCK)		
		INNER JOIN #PetCombos p WITH (NOLOCK) on c.ConsumerCombinationID = p.ConsumerCombinationID			
		WHERE C.TranDate BETWEEN @SixMonthsEarlier AND @MaxFileDate			
		GROUP BY c.CINID
	) o on C.CINID = O.CINID

	INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES ('Pets')

	DROP TABLE #PetCombos

	CREATE TABLE #GroceryCombos(ConsumerCombinationID INT NOT NULL)
	
	INSERT INTO #GroceryCombos(ConsumerCombinationID)
	
	SELECT ConsumerCombinationID
	FROM Relational.ConsumerCombination c
	INNER JOIN MI.CustomerAttributeBrand b ON c.BrandID = b.BrandID
	WHERE b.AttributeType = 4
	
	UNION

	SELECT ConsumerCombinationID
	FROM Relational.ConsumerCombination c
	INNER JOIN MI.CustomerAttributeMCC m ON c.MCCID = m.MCCID
	WHERE m.AttributeType = 4

	ALTER TABLE #GroceryCombos ADD PRIMARY KEY(ConsumerCombinationID)

	UPDATE Relational.CustomerAttribute SET OnlineGroceriesRegular = 1
	FROM Relational.CustomerAttribute c
	INNER JOIN 
	(
		SELECT C.CINID, COUNT(1) AS Frequency	
		FROM Relational.ConsumerTransaction C WITH (NOLOCK)
		INNER JOIN #GroceryCombos g WITH (NOLOCK) ON C.ConsumerCombinationID = g.ConsumerCombinationID	
		WHERE C.IsOnline = 1 --Online transactions	
		AND C.TranDate BETWEEN @ThreeMonthsEarlier AND @MaxFileDate -- Three month period	
		GROUP BY C.CINID	
		HAVING COUNT(1) >=3
	) o on C.CINID = O.CINID

	INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES('OnlineGroceriesRegular')

	UPDATE Relational.CustomerAttribute SET OnlineGroceriesTentative = 1
	FROM Relational.CustomerAttribute c
	INNER JOIN 
	(
		SELECT C.CINID, COUNT(1) AS Frequency	
		FROM Relational.ConsumerTransaction C	WITH (NOLOCK)
		INNER JOIN #GroceryCombos g WITH (NOLOCK) ON c.ConsumerCombinationID = g.ConsumerCombinationID
		WHERE C.IsOnline = 1 --Online transactions	
		AND C.TranDate BETWEEN @MinFileDate AND @MaxFileDate -- One year period	
		GROUP BY C.CINID
	) o on C.CINID = O.CINID

	INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES('OnlineGroceriesTentative')

	DROP TABLE #GroceryCombos
	
	/*
	JEA 03/01/2013 ONLINE/OFFLINE SHOPPING SECTION BEGINS
	*/
	
	CREATE TABLE #CustomerOnline(CINID INT PRIMARY KEY
	, TotalSpend MONEY
	, OnlineSpend MONEY)

	CREATE TABLE #CustTotal(CINID INT PRIMARY KEY, Spend MONEY)

	CREATE TABLE #CustOnline(CINID INT PRIMARY KEY, Spend MONEY)

	INSERT INTO #CustTotal(CINID, Spend)
	SELECT ct.CINID, SUM(ct.Amount)
	FROM Relational.ConsumerTransaction ct
	INNER JOIN Relational.ConsumerSector cs ON ct.ConsumerCombinationID = cs.ConsumerCombinationID
	WHERE ct.TranDate BETWEEN @MinFileDate AND @MaxFileDate
	GROUP BY ct.CINID
	HAVING SUM(ct.Amount) > 0

	INSERT INTO #CustOnline(CINID, Spend)
	SELECT ct.CINID, SUM(ct.Amount)
	FROM Relational.ConsumerTransaction ct
	INNER JOIN Relational.ConsumerSector cs ON ct.ConsumerCombinationID = cs.ConsumerCombinationID
	WHERE ct.TranDate BETWEEN @MinFileDate AND @MaxFileDate
	AND ct.IsOnline = 1
	GROUP BY ct.CINID
	HAVING SUM(ct.Amount) > 0

	INSERT INTO #CustomerOnline(CINID, TotalSpend, OnlineSpend)
	SELECT COALESCE(T.CINID, O.CINID)
	, ISNULL(SUM(T.Amount),0) AS TotalSpend
	, ISNULL(SUM(O.Amount),0) AS OnlineSpend
	FROM #CustTotal T
	FULL OUTER JOIN #CustOnline O ON T.CINID = O.CINID
	HAVING SUM(t.Amount) > 0 OR SUM(o.Amount) > 0
	
	INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES('Online and Offline preparation')
	
	UPDATE Relational.CustomerAttribute SET OnlineOnly = 1
	FROM Relational.CustomerAttribute a
	INNER JOIN #CustomerOnline c ON a.CINID = c.CINID
	WHERE TotalSpend > 0
	AND OnlineSpend = TotalSpend
	
	INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES('OnlineOnly')
	
	UPDATE Relational.CustomerAttribute SET OnlineAndOffLine = 1
	FROM Relational.CustomerAttribute a
	INNER JOIN #CustomerOnline c ON a.CINID = c.CINID
	WHERE TotalSpend > 0
	AND OnlineSpend > 0
	AND OnlineSpend < TotalSpend
	
	INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES('OnlineAndOffline')
	
	UPDATE Relational.CustomerAttribute SET OfflineOnly = 1
	FROM Relational.CustomerAttribute a
	INNER JOIN #CustomerOnline c ON a.CINID = c.CINID
	WHERE TotalSpend > 0
	AND OnlineSpend <= 0
	
	INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES('OfflineOnly')

	DROP TABLE #CustomerOnline
	
	/*
	JEA 03/01/2013 ONLINE/OFFLINE SHOPPING SECTION ENDS
	*/
	
	--JEA 23/04/2013 REFRESH OF THIS SECTION DISCONTINUED
	--JEA 07/01/2013 VALUE/FREQUENCY SECTION BEGINS

	CREATE TABLE #RecencyCombosCoalition(ConsumerCombinationID INT NOT NULL)
	
	CREATE TABLE #RecencyCombosNonCoalition(ConsumerCombinationID INT NOT NULL)
	
	INSERT INTO #RecencyCombosCoalition(ConsumerCombinationID)
	SELECT bs.ConsumerCombinationID
	FROM Relational.ConsumerSector BS
	INNER JOIN Relational.Brand b on bs.BrandID = b.BrandID
	WHERE b.IsLivePartner = 1
	
	INSERT INTO #RecencyCombosNonCoalition(ConsumerCombinationID)
	SELECT bs.ConsumerCombinationID
	FROM Relational.ConsumerSector BS
	INNER JOIN Relational.Brand b on bs.BrandID = b.BrandID
	WHERE b.IsLivePartner = 0
	
	ALTER TABLE #RecencyBrandMIDs ADD PRIMARY KEY(ConsumerCombinationID)
	
	ALTER TABLE #RecencyBrandMIDsCoalition ADD PRIMARY KEY(ConsumerCombinationID)
	
	ALTER TABLE #RecencyBrandMIDsNonCoalition ADD PRIMARY KEY(ConsumerCombinationID)

	UPDATE Relational.CustomerAttribute SET
		RecencyOnline = c.RecencyOnline
	FROM Relational.CustomerAttribute a
	INNER JOIN
		(SELECT ct.CINID, MAX(ct.TranDate) AS RecencyOnline
			FROM Relational.ConsumerTransaction ct
			INNER JOIN Relational.ConsumerSector cs ON ct.ConsumerCombinationID = cs.ConsumerCombinationID
			WHERE ct.IsOnline = 1
			GROUP BY ct.CINID
		) c ON a.CINID = c.CINID

	UPDATE Relational.CustomerAttribute SET
		RecencyOffline = c.RecencyOffline
	FROM Relational.CustomerAttribute a
	INNER JOIN
		(SELECT ct.CINID, MAX(ct.TranDate) AS RecencyOffline
			FROM Relational.ConsumerTransaction ct
			INNER JOIN Relational.ConsumerSector cs ON ct.ConsumerCombinationID = cs.ConsumerCombinationID
			WHERE ct.IsOnline = 0
			GROUP BY ct.CINID
		) c ON a.CINID = c.CINID

	UPDATE Relational.CustomerAttribute SET
		FirstTranDate = c.FirstTranDate
	FROM Relational.CustomerAttribute a
	INNER JOIN
		(SELECT ct.CINID, MIN(ct.TranDate) AS FirstTranDate
			FROM Relational.ConsumerTransaction ct
			INNER JOIN Relational.ConsumerSector cs ON ct.ConsumerCombinationID = cs.ConsumerCombinationID
			GROUP BY ct.CINID
		) c ON a.CINID = c.CINID
	
	UPDATE Relational.CustomerAttribute SET
		RecencyCoalition = v.RecencyCoalition
	FROM Relational.CustomerAttribute c
	INNER JOIN
	(
		SELECT C.CINID
		, MAX(TranDate) AS RecencyCoalition
		FROM Relational.ConsumerTransaction c WITH (NOLOCK)
		INNER JOIN #RecencyCombosCoalition b ON c.ConsumerCombinationID = b.ConsumerCombinationID
		WHERE C.IsRefund = 0
		GROUP BY C.CINID
	) v ON C.CINID = V.CINID
	
	UPDATE Relational.CustomerAttribute SET
		RecencyNonCoalition = v.RecencyNonCoalition
	FROM Relational.CustomerAttribute c
	INNER JOIN
	(
		SELECT C.CINID
		, MAX(TranDate) AS RecencyNonCoalition
		FROM Relational.ConsumerTransaction c WITH (NOLOCK)
		INNER JOIN #RecencyCombosNonCoalition b ON c.ConsumerCombinationID = b.ConsumerCombinationID
		WHERE C.IsRefund = 0
		GROUP BY C.CINID
	) v ON C.CINID = V.CINID
	
	DROP TABLE #RecencyCombosCoalition
	DROP TABLE #RecencyCombosNonCoalition
	
	INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES('Recency')
	
	/*
	JEA 03/01/2013 VALUE/FREQUENCY SECTION ENDS
	*/

	CREATE TABLE #CarCombos(ConsumerCombinationID INT NOT NULL)
	
	INSERT INTO #CarCombos(ConsumerCombinationID)
	
	SELECT ConsumerCombinationID
	FROM Relational.ConsumerCombination c
	INNER JOIN MI.CustomerAttributeBrand b ON c.BrandID = b.BrandID
	WHERE b.AttributeType = 6
	
	UNION
	
	SELECT ConsumerCombinationID
	FROM Relational.ConsumerCombination c
	INNER JOIN Relational.Brand b on c.BrandID = b.BrandID
	WHERE B.SectorID = 4
	
	UNION

	SELECT ConsumerCombinationID
	FROM Relational.ConsumerCombination c
	INNER JOIN MI.CustomerAttributeMCC m ON c.MCCID = m.MCCID
	WHERE m.AttributeType = 1

	UNION
	
	SELECT ConsumerCombinationID
	FROM Relational.ConsumerCombination c
	INNER JOIN Relational.MCCList M on C.MCCID = M.MCCID
	WHERE M.SectorID = 4
	AND c.BrandID = 944

	ALTER TABLE #CarCombos ADD PRIMARY KEY(ConsumerCombinationID)

	UPDATE Relational.CustomerAttribute SET CarOwner = 1
	FROM Relational.CustomerAttribute c
	INNER JOIN 
	(
		SELECT DISTINCT c.CINID
		FROM Relational.ConsumerTransaction c WITH (NOLOCK)
		INNER JOIN #CarCombos p WITH (NOLOCK) on c.ConsumerCombinationID = p.ConsumerCombinationID	
		WHERE C.TranDate BETWEEN @MinFileDate AND @MaxFileDate	
		GROUP BY c.CINID	
	) o ON c.CINID = o.CINID

	DROP TABLE #CarCombos
		
	INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES('CarOwner')
	
	UPDATE relational.CustomerAttribute 
	SET FrequencyYearRetail = t.Frequency, ValueYearRetail = t.Value, RecencyYearRetail = t.MostRecent
		, RecencyYearRetailDays = DATEDIFF(d, t.MostRecent, GETDATE())
	FROM Relational.CustomerAttribute c WITH (NOLOCK)
	INNER JOIN (SELECT CINID, COUNT(1) AS Frequency, SUM(Amount) AS Value, MAX(TranDate) As MostRecent
		FROM Relational.ConsumerTransaction c WITH (NOLOCK)
		INNER JOIN Relational.ConsumerSector b WITH (NOLOCK) on c.ConsumerCombinationID = b.ConsumerCombinationID
		WHERE C.TranDate BETWEEN @MinFileDate AND @MaxFileDate
		GROUP BY CINID
	) t ON c.CINID = t.CINID
	
	INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES('Retail Frequency/Spend')
	
	--Bank ID - set to 2 by default
	UPDATE Relational.CustomerAttribute SET BankID = b.BankID
	FROM Relational.CustomerAttribute A
	INNER JOIN
	(SELECT CINID, max(bankid) AS BankID
	FROM Relational.ConsumerTransaction with (nolock) 
	GROUP BY CINID) B ON A.CINID = B.CINID

	--blank the details of all opted out customers
	UPDATE Relational.CustomerAttribute SET OutdoorHiking = 0
		, Parent = 0
		, ParentOfYoung = 0
		, Gambling = 0
		, Pets = 0
		, OnlineGroceriesRegular = 0
		, OnlineGroceriesTentative = 0
		, OnlineOnly = 0
		, OnlineAndOffline = 0
		, OfflineOnly = 0
		, NotShopped = 0
		, RecencyOnline = null
		, RecencyOffline = null
		, RecencyCoalition = null
		, RecencyNonCoalition = null
		, FirstTranDate = null --this excludes all opted out customers from customer base selection
		, VisitsOnline = 0
		, VisitsOffline = 0
		, VisitsCoalition = 0
		, VisitsNonCoalition = 0
		, CarOwner = 0
		, ValueMonthTotal = 0
		, ValueMonthOnline = 0
		, ValueMonthCoalition = 0
		, FrequencyMonthTotal = 0
		, FrequencyMonthOnline = 0
		, FrequencyMonthCoalition = 0
		, FrequencyYearRetail = 0
		, ValueYearRetail = 0
		, RecencyYearRetailDays = NULL
		--, BankID = 0 -- NB: BankID still used
	FROM Relational.CustomerAttribute c
	INNER JOIN Relational.CINOptOutList o ON C.CINID = O.CINID

	ALTER INDEX IX_CustomerAttribute_FrequencyYearRetail ON Relational.CustomerAttribute REBUILD
	ALTER INDEX IX_CustomerAttribute_ValueYearRetail ON Relational.CustomerAttribute REBUILD
	ALTER INDEX [PK__Customer__A46D9A9F3BA0BFE9] ON Relational.CustomerAttribute REBUILD
	ALTER INDEX IX_CustomerAttribute_FirstTranDate ON Relational.CustomerAttribute REBUILD
	ALTER INDEX IX_CustomerAttribute_BankIDFirstTranDate ON Relational.CustomerAttribute REBUILD

	UPDATE Relational.CustomerAttributeDates set StartDate = @MinFileDate, EndDate = @MaxFileDate

	INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES('Rebuild Indexes')
	
	IF EXISTS(SELECT * FROM sys.tables t 
			INNER JOIN sys.schemas s on t.schema_id = s.schema_id
			WHERE s.name = 'InsightArchive'
			AND t.name = 'WETSFixedBase')
	BEGIN
		DROP TABLE InsightArchive.WETSFixedBase
	END

	EXEC Relational.CustomerBase_Generate 'WETSFixedBase', @MinFileDate, @MaxFileDate,0, 1 --accept defaults

	INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES('Refresh WETSFixedBase')

	DELETE FROM Relational.TotalSectorSpend
	
	INSERT INTO Relational.TotalSectorSpend(BrandID
	, SectorID
	, TotalAmount
	, TranCount
	, CustomerCount
	, TotalAmountOnline
	, TranCountOnline
	, CustomerCountOnline
	)
	SELECT		bms.BrandID
				,bms.SectorID			
				,SUM (c.Amount) as totalamount
				,COUNT(1) as TranCount
				,COUNT (distinct c.CINID) as CustomerCount
				,0
				,0
				,0
	FROM		Relational.ConsumerTransaction c with (nolock) 
	INNER JOIN	Relational.ConsumerSector bms on c.ConsumerCombinationID = bms.ConsumerCombinationID
	INNER JOIN	InsightArchive.WETSFixedBase w ON c.CINID = w.CINID
	WHERE		c.TranDate between @MinFileDate and @MaxFileDate
	AND c.Amount > 0
	GROUP BY	bms.BrandID
				,bms.SectorID
	ORDER BY bms.BrandID
				,bms.SectorID
				
	UPDATE Relational.TotalSectorSpend
	SET TotalAmountOnline = O.TotalAmountOnline
		, TranCountOnline = O.TranCountOnline
		, CustomerCountOnline = O.CustomerCountOnline
	FROM Relational.TotalSectorSpend TSS
	INNER JOIN (
		SELECT		bms.BrandID			
				,SUM (c.Amount) as TotalAmountOnline
				,COUNT(1) as TranCountOnline
				,COUNT (distinct c.CINID) as CustomerCountOnline
		FROM		Relational.ConsumerTransaction c with (nolock) 
		JOIN		Relational.ConsumerSector bms on c.ConsumerCombinationID = bms.ConsumerCombinationID
		WHERE		c.TranDate between @MinFileDate and @MaxFileDate
		AND C.IsOnline = 1
		GROUP BY	bms.BrandID
	) O ON TSS.BrandID = O.BrandID
				
	INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES('Refresh TotalSectorSpend')
				
END