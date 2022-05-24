
-- =============================================
-- Author:		JEA
-- Create date: 29/11/2012
-- Description:	Refreshes customer attributes
-- =============================================
CREATE PROCEDURE [gas].[CustomerAttributes_Refresh_OLD]
	
AS
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @MaxFileDate DATE, @MinFileDate DATE
	SET @MaxFileDate = DATEADD(day, -7, getdate())
	
	--first day of the current month
	SET @MaxFileDate = CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(GETDATE())-1),GETDATE()),101)
	--previous year
	SET @MinFileDate = DATEADD(YEAR, -1, @MaxFileDate)
	--last day of that year
	SET @MaxFileDate = DATEADD(DAY, -1, @MaxFileDate)

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
	
	--BRANDMIDSECTOR REFRESH SECTION BEGINS
	
	ALTER INDEX IX_BrandMIDSector_BrandID ON Relational.BrandMIDSector DISABLE
	ALTER INDEX IX_BrandMIDSector_SectorID ON Relational.BrandMIDSector DISABLE
	
	DELETE FROM Relational.BrandMIDSector

	INSERT INTO Relational.BrandMIDSector(BrandMIDID, BrandID, SectorID)
	SELECT bm.BrandMIDID, bm.BrandID, b.SectorID
	FROM Relational.BrandMID bm
	INNER JOIN Relational.Brand b on bm.BrandID = b.BrandID
	LEFT OUTER JOIN (SELECT BrandID
					  FROM Relational.BrandTagBrand
					  WHERE BrandTagID = 4) t on b.BrandID = t.BrandID
	WHERE b.SectorID > 2
	AND t.BrandID IS NULL

	SELECT BrandMIDID
	INTO #UnbrandedBrandMIDs
	FROM Relational.BrandMID
	WHERE BrandID = 944
	AND Country = 'GB'

	ALTER TABLE #UnbrandedBrandMIDs ADD PRIMARY KEY(BrandMIDID)

	SELECT U.BrandMIDID, ct.MCC, COUNT(1) as Frequency
	INTO #BrandMIDMCCStage
	FROM Relational.CardTransaction ct WITH (NOLOCK)
	INNER JOIN #UnbrandedBrandMIDs u ON CT.BrandMIDID = U.BrandMIDID
	WHERE ct.MCC != '7995' --gambling
	GROUP BY U.BrandMIDID, ct.MCC

	DROP TABLE #UnbrandedBrandMIDs

	SELECT b.BrandMIDID, m.SectorID, SUM(b.Frequency) AS Frequency
	INTO #BrandSectorStage
	FROM #BrandMIDMCCStage b
	INNER JOIN Relational.MCCList m on b.MCC = m.MCC
	GROUP BY b.BrandMIDID, m.SectorID

	SELECT BrandMIDID, MAX(Frequency) AS Frequency, CAST(NULL as TinyInt) AS SectorID
	INTO #MultipleSectors
	FROM
	(
		SELECT bss.BrandMIDID, bss.SectorID, bss.Frequency
		FROM #BrandSectorStage bss
		INNER JOIN (SELECT BrandMIDID, COUNT(DISTINCT SectorID) AS SectorFrequency
					FROM #BrandSectorStage
					GROUP BY BrandMIDID
					HAVING COUNT(DISTINCT SectorID) > 1) sf on bss.BrandMIDID = sf.BrandMIDID
		
	) m
	GROUP BY BrandMIDID

	UPDATE #MultipleSectors SET SectorID = b.SectorID
	FROM #MultipleSectors m
	INNER JOIN #BrandSectorStage b on m.BrandMIDID = b.BrandMIDID and m.Frequency = b.Frequency

	DELETE FROM #BrandSectorStage
	FROM #BrandSectorStage bss
	INNER JOIN #MultipleSectors m on bss.BrandMIDID = m.BrandMIDID and bss.SectorID != m.SectorID

	DELETE FROM #BrandSectorStage
	WHERE SectorID IN (1,2) -- REMOVE UNBRANDED ENTRIES FOR B-TO-B AND FINANCIAL TRANSFER

	INSERT INTO Relational.BrandMIDSector(BrandMIDID,  BrandID, SectorID)
	SELECT BrandMIDID, 944, SectorID
	FROM #BrandSectorStage bss
	ORDER BY BrandMIDID

	ALTER INDEX IX_BrandMIDSector_BrandID ON Relational.BrandMIDSector REBUILD
	ALTER INDEX IX_BrandMIDSector_SectorID ON Relational.BrandMIDSector REBUILD
	ALTER INDEX PK_BrandMIDSector ON Relational.BrandMIDSector REBUILD
	ALTER INDEX IX_CustomerAttribute_FirstTranDate ON Relational.CustomerAttribute REBUILD
	
	INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES('Refresh BrandMIDSector')
	
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

	--23/04/2013 JEA Attribute refresh discontinued
	--UPDATE Relational.CustomerAttribute SET OutdoorHiking = 1
	--FROM Relational.CustomerAttribute c
	--INNER JOIN 
	--(
	--	SELECT  c.CINID, COUNT(1) AS Frequency			
	--	FROM Relational.CardTransaction c with (nolock)	
	--	INNER JOIN Relational.BrandMID b with (nolock) on c.BrandMIDID = b.BrandMIDID			
	--	WHERE c.MCC in ('5699','5998') or b.BrandID in (284	/*Millets*/, 104 /*Cotswold Outdoor*/
	--		, 178	/*Go Outdoors*/, 158 /*Field and Trek*/, 296 /*Mountain Warehouse*/
	--		, 48 /*Blacks*/, 1172 /*Tiso*/, 1173 /*Nevisport*/, 1174 /*Berghaus*/
	--		, 1175 /*Springfield Camping*/, 1176 /*webtogs*/)
	--	AND C.TranDate BETWEEN DATEADD(MONTH, -6, @MaxFileDate) AND @MaxFileDate	
	--	GROUP BY c.CINID
	--	HAVING COUNT(1) > 1
	--) o on c.CINID = o.CINID

	--INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	--VALUES('OutdoorHiking')

	UPDATE Relational.CustomerAttribute SET Parent = 1
	FROM Relational.CustomerAttribute c
	INNER JOIN 
	(
		SELECT c.CINID, COUNT(1) AS Frequency	
		FROM Relational.CardTransaction c WITH (NOLOCK)
		INNER JOIN Relational.BrandMID b WITH (NOLOCK) on c.BrandMIDID = b.BrandMIDID	
		WHERE (B.BrandID IN	
		(	
		2 --Adams Childrenswear
		,125 --Disney Store
		,295 --Mothercare
		,462 --Toymaster
		,463 --Toys R Us
		,464 --Toyzone
		,602 --NappyShop.co.uk
		,742 --Kids Toy World
		,743 --Outdoor Toy World
		,826 --Club Penguin
		,839 --Euro Disney
		,861 --Mothercare.com
		,990 --Tots To Travel
		,1080 -- Alton Towers
		,1167 -- Thorpe Park
		--,1168 -- Butlins
		,1169 --Lightwater valley
		
		--- JH Added further Childrens Brands
		,358	--Pumpkin Patch
		,134	--Early Learning Centre
		,269	--Mamas & Papas
		,1079	--Kiddicare
		,191	--Hamleys
		,70		--Build a Bear
		,432	--The Entertainer
		
			---VM added
		, 1202 -- Jo Jo Maman 
		, 1203 -- Precious Little One
		, 1204 -- Polarn Pyret
		, 1205 -- Igloo Kids
		, 1206 -- One small step one giant leap
		, 1207 -- Petit Bateau
		, 1208 -- Little Vips
		, 1209 -- The Kids Window
		, 1210 -- ChildCare Voucher
		, 1211 -- NCT Courses
		, 1212 -- Kiddisave
		, 1213 -- National Childbirth Trust
		, 1214 -- Rawcliffes
		, 1220 -- KidsWorld
		, 1218 -- Bambino Direct
		, 1219 -- Trutex
		, 1221 -- School Blazer
		, 1222 -- Skoolkit
		)	
		OR c.MCC IN	
		(	
			'7295' --Babysitting services
			,'8211' --Elementary and secondary schools
			,'8351' --Child care services
		))	
		AND C.TranDate BETWEEN DATEADD(MONTH, -6, @MaxFileDate) AND @MaxFileDate	
		GROUP BY c.CINID	
		HAVING COUNT(1) >= 2
	) o ON c.CINID = o.CINID

	INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES('Parent')

	UPDATE Relational.CustomerAttribute SET ParentOfYoung = 1
	FROM Relational.CustomerAttribute c
	INNER JOIN 
	(
		SELECT c.CINID, COUNT(1) AS Frequency	
		FROM Relational.CardTransaction c WITH (NOLOCK)
		INNER JOIN Relational.BrandMID b WITH (NOLOCK) on c.BrandMIDID = b.BrandMIDID	
		WHERE (B.BrandID IN	
		(	
			--125 --Disney Store
			295 --Mothercare
			,602 --NappyShop.co.uk
			,861 --Mothercare.com
			,990 --Tots To Travel

			--- JH Added further Childrens Brands
			,358	--Pumpkin Patch
			,134	--Early Learning Centre
			,269	--Mamas & Papas
			,1079	--Kiddicare
			
			---VM added
			, 1202 -- Jo Jo Maman 
			, 1203 -- Precious Little One
			, 1204 -- Polarn Pyret
			, 1205 -- Igloo Kids
			, 1207 -- Petit Bateau
			, 1208 -- Little Vips
			, 1209 -- The Kids Window
			, 1210 -- ChildCare Voucher
			, 1211 -- NCT Courses
			, 1212 -- Kiddisave
			, 1213 -- National Childbirth Trust
			, 1218 -- Bambino Direct
		)	)	
		AND C.TranDate BETWEEN DATEADD(MONTH, -6, @MaxFileDate) AND @MaxFileDate	
		GROUP BY c.CINID	
		HAVING COUNT(1) >= 2
	) o on c.CINID = o.CINID	

	INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES('ParentOfYoung')

	--23/04/2013 JEA Attribute refresh discontinued
	--UPDATE Relational.CustomerAttribute SET Gambling = 1
	--FROM Relational.CustomerAttribute c
	--INNER JOIN 
	--(
	--	SELECT CINID, COUNT(1) AS CustomerCount
	--	FROM Relational.CardTransaction c WITH (NOLOCK)
	--	INNER JOIN Relational.BrandMID  bm WITH (NOLOCK) ON c.BrandMIDID = bm.BrandMIDID
	--	WHERE c.MCC = '7995'
	--	  AND TranDate BETWEEN DATEADD(month,-6,@MaxFileDate) and @MaxFileDate
	--	  AND bm.BrandID <> 1166  ----National Lottery
	--	GROUP BY CINID
	--	 HAVING COUNT(1) >= 2
	--) o ON C.CINID = O.CINID

	--INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	--VALUES('Gambling')

	UPDATE Relational.CustomerAttribute SET Pets = 1
	FROM Relational.CustomerAttribute c
	INNER JOIN 
	(
		SELECT c.CINID, COUNT(1) AS Frequency			
		FROM Relational.CardTransaction c WITH (NOLOCK)		
		INNER JOIN Relational.BrandMID b WITH (NOLOCK) on c.BrandMIDID = b.BrandMIDID			
		WHERE ( c.MCC IN ('5995', '0742') -- Pet shops; vets		
		)			
		AND C.TranDate BETWEEN DATEADD(MONTH, -6, @MaxFileDate) AND @MaxFileDate			
		GROUP BY c.CINID
	) o on C.CINID = O.CINID

	INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES ('Pets')

	UPDATE Relational.CustomerAttribute SET OnlineGroceriesRegular = 1
	FROM Relational.CustomerAttribute c
	INNER JOIN 
	(
		SELECT C.CINID, COUNT(1) AS Frequency	
		FROM Relational.CardTransaction C WITH (NOLOCK)
		INNER JOIN Relational.BrandMID B WITH (NOLOCK) ON C.BrandMIDID = B.BrandMIDID	
		WHERE B.BrandID IN	
		(	
			5, --Aldi	
			21, --Asda	
			92, --Co-op	
			254, --Lidl	
			292, --Morrisons	
			312, --Ocado	
			379, --Sainsburys	
			425, --Tesco	
			485 --Waitrose	
		)	
		AND C.CardholderPresentData = '5' --Online transactions	
		AND C.TranDate BETWEEN DATEADD(MONTH, -3, @MaxFileDate) AND @MaxFileDate -- Three month period	
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
		FROM Relational.CardTransaction C	WITH (NOLOCK)
		INNER JOIN Relational.BrandMID B WITH (NOLOCK) ON C.BrandMIDID = B.BrandMIDID	
		WHERE B.BrandID IN	
		(	
		5, --Aldi	
		21, --Asda	
		92, --Co-op	
		254, --Lidl	
		292, --Morrisons	
		312, --Ocado	
		379, --Sainsburys	
		425, --Tesco	
		485 --Waitrose	
		)	
		AND C.CardholderPresentData = '5' --Online transactions	
		AND C.TranDate BETWEEN @MinFileDate AND @MaxFileDate -- One year period	
		GROUP BY C.CINID
	) o on C.CINID = O.CINID

	INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES('OnlineGroceriesTentative')
	
	/*
	JEA 03/01/2013 ONLINE/OFFLINE SHOPPING SECTION BEGINS
	*/
	
	CREATE TABLE #CustomerOnline(CINID INT PRIMARY KEY
	, TotalSpend MONEY
	, OnlineSpend MONEY)

	INSERT INTO #CustomerOnline(CINID, TotalSpend, OnlineSpend)
	SELECT CINID
	, SUM(Amount) AS TotalSpend
	, SUM(CASE CardholderPresentData WHEN '5' THEN Amount ELSE 0 END) AS OnlineSpend
	FROM Relational.CardTransaction CT WITH (NOLOCK)
	INNER JOIN Relational.BrandMIDSector B ON CT.BrandMIDID = B.BrandMIDID --JEA 23/04/2013 Online/offline spend figures are now retail based
	WHERE TranDate BETWEEN @MinFileDate AND @MaxFileDate
	GROUP BY CINID

	DELETE FROM #CustomerOnline
	WHERE TotalSpend <= 0
	AND OnlineSpend <= 0
	
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
	
	--23/04/2013 JEA Attribute refresh discontinued
	--UPDATE Relational.CustomerAttribute SET NotShopped = 1
	--FROM Relational.CustomerAttribute a
	--LEFT OUTER JOIN #CustomerOnline c ON a.CINID = c.CINID
	--WHERE C.CINID IS NULL
	
	--INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	--VALUES('NotShopped')

	DROP TABLE #CustomerOnline
	
	/*
	JEA 03/01/2013 ONLINE/OFFLINE SHOPPING SECTION ENDS
	*/
	
	--JEA 23/04/2013 REFRESH OF THIS SECTION DISCONTINUED
	--JEA 07/01/2013 VALUE/FREQUENCY SECTION BEGINS
	
	--UPDATE Relational.CustomerAttribute SET
	--ValueMonthTotal = v.TotalValue
	--, ValueMonthOnline = v.OnlineValue
	--, ValueMonthCoalition = v.CoalitionValue
	--, FrequencyMonthTotal = v.TotalFrequency
	--, FrequencyMonthOnline = v.OnlineFrequency
	--, FrequencyMonthCoalition = v.CoalitionFrequency
	--FROM Relational.CustomerAttribute c
	--INNER JOIN
	--(
	--	SELECT c.CINID
	--	, SUM(c.Amount) AS TotalValue
	--	, SUM(CASE c.CardholderPresentData WHEN '5' THEN c.Amount ELSE 0 END) AS OnlineValue
	--	, SUM(CASE b.IsLivePartner WHEN 1 THEN c.Amount ELSE 0 END) AS CoalitionValue
	--	, COUNT(1) AS TotalFrequency
	--	, SUM(CASE c.CardholderPresentData WHEN '5' THEN 1 ELSE 0 END) AS OnlineFrequency
	--	, SUM(CASE b.IsLivePartner WHEN 1 THEN 1 ELSE 0 END) AS CoalitionFrequency
	--	FROM Relational.CardTransaction c WITH (NOLOCK)
	--	INNER JOIN Relational.BrandMID bm WITH (NOLOCK) on c.BrandMIDID = bm.BrandMIDID
	--	INNER JOIN Relational.Brand b WITH (NOLOCK) on bm.BrandID = b.BrandID
	--	WHERE c.TranDate BETWEEN DATEADD(MONTH, -1, @MaxFileDate) AND @MaxFileDate
	--	GROUP BY C.CINID
	--) v on c.CINID = v.CINID
	
	--INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	--VALUES('Value and frequency figures and percentages')
	
	CREATE TABLE #RecencyBrandMIDs(BrandMIDID INT NOT NULL)
	
	CREATE TABLE #RecencyBrandMIDsCoalition(BrandMIDID INT NOT NULL)
	
	CREATE TABLE #RecencyBrandMIDsNonCoalition(BrandMIDID INT NOT NULL)
	
	INSERT INTO #RecencyBrandMIDs(BrandMIDID)
	SELECT bs.BrandMIDID
	FROM Relational.BrandMIDSector BS
	
	INSERT INTO #RecencyBrandMIDsCoalition(BrandMIDID)
	SELECT bs.BrandMIDID
	FROM Relational.BrandMIDSector BS
	INNER JOIN Relational.Brand b on bs.BrandID = b.BrandID
	WHERE b.IsLivePartner = 1
	
	INSERT INTO #RecencyBrandMIDsNonCoalition(BrandMIDID)
	SELECT bs.BrandMIDID
	FROM Relational.BrandMIDSector BS
	INNER JOIN Relational.Brand b on bs.BrandID = b.BrandID
	WHERE b.IsLivePartner = 0
	
	ALTER TABLE #RecencyBrandMIDs ADD PRIMARY KEY(BrandMIDID)
	
	ALTER TABLE #RecencyBrandMIDsCoalition ADD PRIMARY KEY(BrandMIDID)
	
	ALTER TABLE #RecencyBrandMIDsNonCoalition ADD PRIMARY KEY(BrandMIDID)
	
	UPDATE Relational.CustomerAttribute SET
		RecencyOnline = v.RecencyOnline
		, RecencyOffline = v.RecencyOffline
		, FirstTranDate = v.FirstTranDate
	FROM Relational.CustomerAttribute c
	INNER JOIN
	(
		SELECT C.CINID
		, MAX(CASE WHEN C.CardholderPresentData = '5' THEN TranDate ELSE NULL END) AS RecencyOnline
		, MAX(CASE WHEN C.CardholderPresentData = '5' THEN NULL ELSE TranDate END) AS RecencyOffline
		, MIN(TranDate) AS FirstTranDate
		FROM Relational.CardTransaction c WITH (NOLOCK)
		INNER JOIN #RecencyBrandMIDs b ON c.BrandMIDID = b.BrandMIDID
		WHERE C.Amount > 0
		GROUP BY C.CINID
	) v ON C.CINID = V.CINID
	
	UPDATE Relational.CustomerAttribute SET
		RecencyCoalition = v.RecencyCoalition
	FROM Relational.CustomerAttribute c
	INNER JOIN
	(
		SELECT C.CINID
		, MAX(TranDate) AS RecencyCoalition
		FROM Relational.CardTransaction c WITH (NOLOCK)
		INNER JOIN #RecencyBrandMIDsCoalition b ON c.BrandMIDID = b.BrandMIDID
		WHERE C.Amount > 0
		GROUP BY C.CINID
	) v ON C.CINID = V.CINID
	
	UPDATE Relational.CustomerAttribute SET
		RecencyNonCoalition = v.RecencyNonCoalition
	FROM Relational.CustomerAttribute c
	INNER JOIN
	(
		SELECT C.CINID
		, MAX(TranDate) AS RecencyNonCoalition
		FROM Relational.CardTransaction c WITH (NOLOCK)
		INNER JOIN #RecencyBrandMIDsNonCoalition b ON c.BrandMIDID = b.BrandMIDID
		WHERE C.Amount > 0
		GROUP BY C.CINID
	) v ON C.CINID = V.CINID
	
	DROP TABLE #RecencyBrandMIDs
	DROP TABLE #RecencyBrandMIDsCoalition
	DROP TABLE #RecencyBrandMIDsNonCoalition
	
	INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES('Recency')
	
	--UPDATE Relational.CustomerAttribute SET
	--	RecencyOnline = v.RecencyOnline
	--	, RecencyOffline = v.RecencyOffline
	--	, RecencyCoalition = v.RecencyCoalition
	--	, RecencyNonCoalition = v.RecencyNonCoalition
	--FROM Relational.CustomerAttribute c
	--INNER JOIN
	--(
	--	SELECT C.CINID
	--	, MAX(CASE WHEN C.CardholderPresentData = '5' THEN TranDate ELSE NULL END) AS RecencyOnline
	--	, MAX(CASE WHEN C.CardholderPresentData = '5' THEN NULL ELSE TranDate END) AS RecencyOffline
	--	, MAX(CASE WHEN B.IsLivePartner = 1 THEN TranDate ELSE NULL END) AS RecencyCoalition
	--	, MAX(CASE WHEN B.IsLivePartner = 1 THEN NULL ELSE TranDate END) AS RecencyNonCoalition
	--	FROM Relational.CardTransaction c WITH (NOLOCK)
	--	INNER JOIN Relational.BrandMID bm WITH (NOLOCK) on c.BrandMIDID = bm.BrandMIDID
	--	INNER JOIN Relational.Brand b WITH (NOLOCK) on bm.BrandID = b.BrandID
	--	WHERE C.Amount > 0
	--	GROUP BY C.CINID
	--) v ON C.CINID = V.CINID
	
	--INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	--VALUES('Recency figures')
	
	--UPDATE Relational.CustomerAttribute SET
	--	VisitsOnline = v.VisitsOnline
	--	, VisitsOffline = v.VisitsOffline
	--	, VisitsCoalition = v.VisitsCoalition
	--	, VisitsNonCoalition = v.VisitsNonCoalition
	--FROM Relational.CustomerAttribute c
	--INNER JOIN
	--(
	--	SELECT C.CINID
	--	, COUNT(DISTINCT CASE WHEN C.CardholderPresentData = '5' THEN TranDate ELSE NULL END) AS VisitsOnline
	--	, COUNT(DISTINCT CASE WHEN C.CardholderPresentData = '5' THEN NULL ELSE TranDate END) AS VisitsOffline
	--	, COUNT(DISTINCT CASE WHEN B.IsLivePartner = 1 THEN TranDate ELSE NULL END) AS VisitsCoalition
	--	, COUNT(DISTINCT CASE WHEN B.IsLivePartner = 1 THEN NULL ELSE TranDate END) AS VisitsNonCoalition
	--	FROM Relational.CardTransaction c WITH (NOLOCK)
	--	INNER JOIN Relational.BrandMID bm WITH (NOLOCK) on c.BrandMIDID = bm.BrandMIDID
	--	INNER JOIN Relational.Brand b WITH (NOLOCK) on bm.BrandID = b.BrandID
	--	WHERE C.Amount > 0
	--	AND C.TranDate BETWEEN DATEADD(MONTH, -1, @MaxFileDate) AND @MaxFileDate
	--	GROUP BY C.CINID
	--) v ON C.CINID = V.CINID
	
	--INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	--VALUES('Visit figures')
	
	/*
	JEA 03/01/2013 VALUE/FREQUENCY SECTION ENDS
	*/
	
	--JEA 04/01/2013 Reworked car owner attribute
	UPDATE Relational.CustomerAttribute SET CarOwner = 1
	FROM Relational.CustomerAttribute c
	INNER JOIN 
		(
			SELECT DISTINCT c.CINID
			FROM Relational.CardTransaction c WITH (nolock)
			INNER JOIN Relational.BrandMID bm on c.BrandMIDID = bm.BrandMIDID
			INNER JOIN Relational.Brand b on bm.BrandID = b.BrandID
			INNER JOIN Relational.MCCList m on c.MCC = m.MCC
			WHERE c.Amount > 0
			AND c.TranDate BETWEEN @MinFileDate AND @MaxFileDate
			AND (
				(b.SectorID = 4 OR m.SectorID = 4) --petrol
				OR b.BrandID = 1264 --DVLA
				OR (m.MCC = '7523' or b.BrandID IN (299,15,30,147,279,360,361,421,35,474,65,567,553,554,565)) -- parking
				OR m.MCC IN ('7542','5511','7531','7534','7535','7538','7549', '8675') --services
		)
		) v on c.CINID = v.CINID
		
	INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES('CarOwner')
	
	UPDATE relational.CustomerAttribute 
	SET FrequencyYearRetail = t.Frequency, ValueYearRetail = t.Value, RecencyYearRetail = t.MostRecent
		, RecencyYearRetailDays = DATEDIFF(d, t.MostRecent, GETDATE())
	FROM Relational.CustomerAttribute c WITH (NOLOCK)
	INNER JOIN (SELECT CINID, COUNT(1) AS Frequency, SUM(Amount) AS Value, MAX(TranDate) As MostRecent
		FROM Relational.CardTransaction c WITH (NOLOCK)
		INNER JOIN Relational.BrandMIDSector b WITH (NOLOCK) on c.BrandMIDID = b.BrandMIDID
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
	FROM Relational.CardTransaction with (nolock) 
	GROUP BY CINID) B ON A.CINID = B.CINID

	--update rainbow bankids
	--UPDATE Relational.CustomerAttribute SET BankID = r.bankID
	--FROM Relational.CustomerAttribute A
	--INNER JOIN
	--(SELECT CINID, max(bankid) as bankid
	--FROM Relational.CardTransactionRainbow with (nolock)
	--GROUP BY CINID) r ON A.CINID = r.CINID


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

	--CREATE INDEX IX_CustomerAttribute_OutdoorHiking ON Relational.CustomerAttribute(OutdoorHiking)
	--CREATE INDEX IX_CustomerAttribute_Parent ON Relational.CustomerAttribute(Parent)
	--CREATE INDEX IX_CustomerAttribute_ParentOfYoung ON Relational.CustomerAttribute(ParentOfYoung)
	--CREATE INDEX IX_CustomerAttribute_Gambling ON Relational.CustomerAttribute(Gambling)
	--CREATE INDEX IX_CustomerAttribute_Pets ON Relational.CustomerAttribute(Pets)
	--CREATE INDEX IX_CustomerAttribute_OnlineGroceriesRegular ON Relational.CustomerAttribute(OnlineGroceriesRegular)
	--CREATE INDEX IX_CustomerAttribute_OnlineGroceriesTentative ON Relational.CustomerAttribute(OnlineGroceriesTentative)
	ALTER INDEX IX_CustomerAttribute_FrequencyYearRetail ON Relational.CustomerAttribute REBUILD
	ALTER INDEX IX_CustomerAttribute_ValueYearRetail ON Relational.CustomerAttribute REBUILD
	ALTER INDEX [PK__Customer__A46D9A9F3BA0BFE9] ON Relational.CustomerAttribute REBUILD
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
	FROM		Relational.CardTransaction c with (nolock) 
	INNER JOIN	Relational.BrandMIDSector bms on c.BrandMIDID = bms.BrandMIDID
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
		FROM		Relational.CardTransaction c with (nolock) 
		JOIN		Relational.BrandMIDSector bms on c.BrandMIDID = bms.BrandMIDID
		WHERE		c.TranDate between @MinFileDate and @MaxFileDate
		AND C.CardholderPresentData = '5'
		GROUP BY	bms.BrandID
	) O ON TSS.BrandID = O.BrandID
				
	INSERT INTO Staging.CustomerAttributeAudit(QueryDesc)
	VALUES('Refresh TotalSectorSpend')
				
END