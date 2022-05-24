-- =============================================
-- Author:		Shaun H
-- Create date: 7th August 2019
-- Description:	Perform a Byron Type Analysis
-- =============================================
CREATE PROCEDURE [Prototype].[Analysis]
	(
		@MainBrand INT,
		@BrandList VARCHAR(200), -- Comma seperated list no spaces, including MainBrand
		@EndDate DATE,
		@Customers VARCHAR(200) = NULL,
		@StartDate DATE = NULL,
		@DriveTime INT = NULL
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--DECLARE @MainBrand INT = 298
	--DECLARE @BrandList VARCHAR(200) = '298,336,337,1077' -- Comma seperated list no spaces, including MainBrand
	--DECLARE @EndDate DATE = '2019-06-30'
	--DECLARE @Customers VARCHAR(200) = NULL --'#MostValuableCustomer',
	--DECLARE @StartDate DATE = '2018-07-01'
	--DECLARE @DriveTime INT = 1

	PRINT @MainBrand
	PRINT @BrandList
	PRINT @EndDate
	PRINT @Customers
	PRINT @StartDate
	PRINT @DriveTime

	DECLARE @time DATETIME

	EXEC Warehouse.Prototype.oo_TimerMessage 'Analysis - Start', @time OUTPUT

	-- Resolve the optional Customers parameter
	IF OBJECT_ID('tempdb..#Customer') IS NOT NULL DROP TABLE #Customer
	CREATE TABLE #Customer
	(
	  CINID INT
	)
	IF @Customers IS NOT NULL
	  BEGIN
		EXEC('
			   INSERT INTO #Customer
				 SELECT
				   CINID
				  FROM ' + @Customers + '
			')
		END
	ELSE
	  BEGIN
		INSERT INTO #Customer
		  SELECT
			CINID
		  FROM	(
				  SELECT 
					CINID
				  FROM Warehouse.Relational.Customer c
				  JOIN Warehouse.Relational.CINList cl
					ON cl.CIN = c.SourceUID
				  WHERE	c.CurrentlyActive = 1
					AND NOT EXISTS
					(
						SELECT	*
						FROM	Warehouse.Staging.Customer_DuplicateSourceUID dup
						WHERE	EndDate IS NULL
							AND c.SourceUID = dup.SourceUID
					)
				 ) a
	  END

	CREATE CLUSTERED INDEX cix_CINID ON #Customer (CINID)

	EXEC Warehouse.Prototype.oo_TimerMessage 'Analysis - #Customer', @time OUTPUT

	-- Demographic Distribution

	IF OBJECT_ID('tempdb..#FullBase') IS NOT NULL DROP TABLE #FullBase
	SELECT	
	  FanID,
	  CINID,
	  Gender,
	  CASE
		WHEN c.AgeCurrent < 18 OR c.AgeCurrent IS NULL THEN '99. Unknown'
		WHEN c.AgeCurrent BETWEEN 18 AND 24 THEN '01. 18 to 24'
		WHEN c.AgeCurrent BETWEEN 25 AND 29 THEN '02. 25 to 29'
		WHEN c.AgeCurrent BETWEEN 30 AND 39 THEN '03. 30 to 39'
		WHEN c.AgeCurrent BETWEEN 40 AND 49 THEN '04. 40 to 49'
		WHEN c.AgeCurrent BETWEEN 50 AND 59 THEN '05. 50 to 59'
		WHEN c.AgeCurrent BETWEEN 60 AND 64 THEN '06. 60 to 64'
		WHEN 65 <= c.AgeCurrent THEN '07. 65+'
	  END AS AgeBand,
	  COALESCE(C.Region, 'Unknown') AS Region,
	  ISNULL(CONCAT(cam.CAMEO_CODE_GROUP,'-',ccg.CAMEO_CODE_GROUP_Category), '99 Unknown') AS CAMEO
	INTO #FullBase			   		 	  
	FROM Warehouse.Relational.Customer C
	JOIN Warehouse.Relational.CINList CL ON CL.CIN = C.SourceUID
	LEFT JOIN Warehouse.Relational.CAMEO CAM ON CAM.Postcode = C.PostCode
	LEFT JOIN Warehouse.Relational.CAMEO_CODE_GROUP CCG ON CCG.CAMEO_CODE_GROUP = CAM.CAMEO_CODE_GROUP
	WHERE	c.CurrentlyActive = 1
		AND	NOT EXISTS
		  (	SELECT 1
			FROM Warehouse.Staging.Customer_DuplicateSourceUID dup
			WHERE c.SourceUID = dup.SourceUID
			  AND dup.EndDate IS NULL)

	CREATE CLUSTERED INDEX cix_CINID ON #FullBase (CINID)

	EXEC Warehouse.Prototype.oo_TimerMessage 'Analysis - #FullBase', @time OUTPUT

	DECLARE @Total_Customers INT = (SELECT COUNT(*) FROM #Customer)
	DECLARE @Total_FullBase INT = (SELECT COUNT(*) FROM #FullBase)

	-- Resolve the optional StartDate parameter to be EndDate - 364 Days if not supplied
	IF @StartDate IS NULL
	  BEGIN
		SET @StartDate = DATEADD(YEAR,-1,DATEADD(DAY,1,@EndDate))
	  END

	-- Resolve the optional DriveTime parameter
	IF @DriveTime IS NULL
	  BEGIN
		SET @DriveTime = 5
	  END

	-- Find BrandNames
	IF OBJECT_ID('tempdb..#Brand') IS NOT NULL DROP TABLE #Brand
	SELECT
	  BrandID,
	  BrandName
	INTO #Brand
	FROM Warehouse.Relational.Brand b
	WHERE CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0

	CREATE CLUSTERED INDEX cix_BrandID ON #Brand (BrandID)

	EXEC Warehouse.Prototype.oo_TimerMessage 'Analysis - #Brand', @time OUTPUT

	-- Find all ConsumerCombinations associated with the Brand + Competitors
	IF OBJECT_ID('tempdb..#ConsumerCombination') IS NOT NULL DROP TABLE #ConsumerCombination
	SELECT
	  ConsumerCombinationID,
	  BrandID
	INTO #ConsumerCombination
	FROM Warehouse.Relational.ConsumerCombination cc
	WHERE CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0

	CREATE CLUSTERED INDEX cix_ConsumerCombinationID ON #ConsumerCombination (ConsumerCombinationID)

	EXEC Warehouse.Prototype.oo_TimerMessage 'Analysis - #ConsumerCombination', @time OUTPUT

	-- Find PostCodes
	IF OBJECT_ID('tempdb..#CC_With_PostCode') IS NOT NULL DROP TABLE #CC_With_PostCode
	SELECT
		cc.ConsumerCombinationID,
		cc.BrandID,
		p.PostCode,
		CASE
		WHEN LEN(p.PostCode) = 5 THEN LEFT(REPLACE(p.PostCode,' ',''),3)
		WHEN LEN(p.PostCode) = 6 THEN LEFT(REPLACE(p.PostCode,' ',''),4)
		WHEN LEN(p.PostCode) = 7 THEN LEFT(REPLACE(p.PostCode,' ',''),5)
		ELSE NULL		
		END AS PostalSector,
		0 AS WithinDriveTime
	INTO #CC_With_PostCode
	FROM #ConsumerCombination cc
	LEFT JOIN Warehouse.AWSFile.ComboPostCode p
		ON cc.ConsumerCombinationID = p.ConsumerCombinationID

	CREATE CLUSTERED INDEX cix_ConsumerCombinationID ON #CC_With_PostCode (ConsumerCombinationID)

	EXEC Warehouse.Prototype.oo_TimerMessage 'Analysis - #CC_With_PostCode', @time OUTPUT

	-- Attempt to find PartnerID
	DECLARE @PartnerID INT = NULL

	SELECT
	  @PartnerID = PartnerID
	FROM Warehouse.Relational.Partner
	WHERE BrandID = @MainBrand


	-- Find Postcodes within the X minute DriveTime vicinity
	IF OBJECT_ID('tempdb..#LocalPostCodes') IS NOT NULL DROP TABLE #LocalPostCodes
	CREATE TABLE #LocalPostCodes
		(
			ToSector VARCHAR(10)
		)

	IF @PartnerID IS NULL
	  BEGIN
		INSERT INTO #LocalPostCodes
			SELECT
			  DISTINCT 
			  REPLACE(dtm.ToSector,' ','') AS ToSector
			FROM #CC_With_PostCode a
			JOIN Warehouse.Relational.DriveTimeMatrix dtm
			  ON a.PostalSector = REPLACE(dtm.FromSector,' ' ,'')
			WHERE BrandID = @MainBrand
			  AND DriveTimeMins <= @DriveTime
	

	  END
	ELSE
	  BEGIN	
		INSERT INTO #LocalPostCodes
			SELECT
			  DISTINCT
			  REPLACE(dtm.ToSector,' ','') AS ToSector
			FROM Warehouse.Relational.Outlet o
			JOIN Warehouse.Relational.DriveTimeMatrix dtm
			  ON o.PostalSector = dtm.FromSector
			WHERE o.PartnerID = @PartnerID
			  AND DriveTimeMins <= @DriveTime

	  END

	CREATE CLUSTERED INDEX cix_ToSector ON #LocalPostCodes (ToSector)

	EXEC Warehouse.Prototype.oo_TimerMessage 'Analysis - #LocalPostCodes', @time OUTPUT

	-- Update the flag to reflect whether they are local (MainBrand is not tagged)
	UPDATE a
	SET WithinDriveTime = 1
	FROM #CC_With_PostCode a
	WHERE EXISTS
		(	SELECT 1
			FROM #LocalPostCodes b
			WHERE a.PostalSector = b.ToSector)
	  AND BrandID != @MainBrand

	EXEC Warehouse.Prototype.oo_TimerMessage 'Analysis - Update #CC_With_PostCode ', @time OUTPUT

	/*
	SELECT
	  BrandID,
	  WithinDriveTime,
	  COUNT(*)
	FROM #CC_With_PostCode
	GROUP BY
	  BrandID,
	  WithinDriveTime
	ORDER BY 2,1
	*/

	IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
	SELECT
	  ct.CINID,
	  ct.Amount,
	  ct.TranDate,
	  cc.ConsumerCombinationID,
	  cc.BrandID,
	  cc.WithinDriveTime
	INTO #Trans
	FROM Warehouse.Relational.ConsumerTransaction_MyRewards ct
	JOIN #CC_With_PostCode cc
	  ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
	JOIN #Customer c
	  ON ct.CINID = c.CINID
	WHERE @StartDate <= ct.TranDate AND ct.TranDate <= @EndDate

	CREATE CLUSTERED INDEX cix_TranDate ON #Trans (TranDate)
	CREATE NONCLUSTERED INDEX nix_TranDate__CINID ON #Trans (TranDate) INCLUDE (CINID) 


	EXEC Warehouse.Prototype.oo_TimerMessage 'Analysis - #Trans', @time OUTPUT

	-- To be used as the ulimate decider where people shop at more than one brand on the most recent day
	IF OBJECT_ID('tempdb..#ShareOfTrans') IS NOT NULL DROP TABLE #ShareOfTrans
	SELECT
	  t.CINID,
	  t.BrandID,
	  t1.TotalTrans,
	  COUNT(*) AS BrandTrans,
	  1.0*COUNT(*)/t1.TotalTrans AS ShareOfTrans
	INTO #ShareOfTrans
	FROM #Trans t
	JOIN 
	(
	  SELECT
		CINID,
		COUNT(*) AS TotalTrans
	  FROM #Trans t
	  WHERE 0 < t.Amount
	  GROUP BY
		CINID
	) t1
	ON t.CINID = t1.CINID
	WHERE 0 < t.Amount
	GROUP BY
	  t.CINID,
	  t.BrandID,
	  t1.TotalTrans

	CREATE CLUSTERED INDEX cix_CINID_BrandID ON #ShareOfTrans (CINID, BrandID)

	EXEC Warehouse.Prototype.oo_TimerMessage 'Analysis - #ShareOfTrans', @time OUTPUT

	IF OBJECT_ID('tempdb..#SpendByDay') IS NOT NULL DROP TABLE #SpendByDay
	SELECT
	  CINID,
	  TranDate,
	  BrandID,
	  SUM(Amount) AS Spend,
	  0 AS LastSpend
	INTO #SpendByDay
	FROM #Trans t
	WHERE 0 < t.Amount
	GROUP BY
	  CINID,
	  TranDate,
	  BrandID

	CREATE CLUSTERED INDEX cix_CINID ON #SpendByDay (CINID)
	CREATE NONCLUSTERED INDEX nix_CINID__TranDate ON #SpendByDay (CINID) INCLUDE (TranDate)

	EXEC Warehouse.Prototype.oo_TimerMessage 'Analysis - #SpendByDay', @time OUTPUT

	IF OBJECT_ID('tempdb..#MaxDate') IS NOT NULL DROP TABLE #MaxDate
	SELECT
	  CINID,
	  MAX(TranDate) AS MaxDate
	INTO #MaxDate
	FROM #SpendByDay
	GROUP BY 
	  CINID

	CREATE CLUSTERED INDEX cix_CINID ON #MaxDate (CINID)
	CREATE NONCLUSTERED INDEX nix_CINID__MaxDate ON #MaxDate (CINID) INCLUDE (MaxDate)

	EXEC Warehouse.Prototype.oo_TimerMessage 'Analysis - #MaxDate', @time OUTPUT

	-- Update #SpendByDay to account for MaxTranDate
	UPDATE a
	SET LastSpend = 1
	FROM #SpendByDay a
	JOIN #MaxDate b
	  ON a.CINID = b.CINID
	 AND a.TranDate = b.MaxDate

	EXEC Warehouse.Prototype.oo_TimerMessage 'Analysis - Update LastSpend', @time OUTPUT

	-- More Than One - Customers who have more than one establishment labelled for their MaxDate
	IF OBJECT_ID('tempdb..#MoreThanOne') IS NOT NULL DROP TABLE #MoreThanOne
	SELECT 
	  CINID
	INTO #MoreThanOne
	FROM #SpendByDay
	WHERE LastSpend = 1
	GROUP BY CINID
	HAVING 1 < COUNT(*)

	CREATE CLUSTERED INDEX cix_CINID ON #MoreThanOne (CINID)

	EXEC Warehouse.Prototype.oo_TimerMessage 'Analysis - #MoreThanOne', @time OUTPUT

	IF OBJECT_ID('tempdb..#LastEstablishment') IS NOT NULL DROP TABLE #LastEstablishment
	SELECT
	  CINID,
	  BrandID
	INTO #LastEstablishment
	FROM
	(
		SELECT
		  a.CINID,
		  a.BrandID,
		  a.ShareOfTrans,
		  ROW_NUMBER() OVER (PARTITION BY a.CINID ORDER BY a.ShareOfTrans DESC, a.BrandID ASC) AS RowNumber
		FROM #ShareOfTrans a
		JOIN #SpendByDay b
		  ON a.CINID = b.CINID
		 AND a.BrandID = b.BrandID
		 AND b.LastSpend = 1
		WHERE EXISTS
			(	SELECT *
				FROM #MoreThanOne b
				WHERE a.CINID = b.CINID
			)
	) c
	WHERE c.RowNumber = 1

	CREATE CLUSTERED INDEX cix_CINID_BrandID ON #LastEstablishment (CINID, BrandID)

	EXEC Warehouse.Prototype.oo_TimerMessage 'Analysis - #LastEstablishment', @time OUTPUT

	UPDATE a
	SET LastSpend = 0
	FROM #SpendByDay a
	WHERE a.LastSpend = 1
	  AND EXISTS
		( SELECT 1
		  FROM #MoreThanOne b
		  WHERE a.CINID = b.CINID)
	  AND NOT EXISTS
		( SELECT 1
		  FROM #LastEstablishment c
		  WHERE a.CINID = c.CINID
			AND a.BrandID = c.BrandID )

	EXEC Warehouse.Prototype.oo_TimerMessage 'Analysis - Update LastSpend', @time OUTPUT


	IF OBJECT_ID('tempdb..#BrandCINID') IS NOT NULL DROP TABLE #BrandCINID
	SELECT
	  DISTINCT
	  BrandID,
	  CINID
	INTO #BrandCINID
	FROM #Trans
	WHERE 0 < Amount

	CREATE CLUSTERED INDEX cix_CINID ON #BrandCINID (CINID)

	EXEC Warehouse.Prototype.oo_TimerMessage 'Analysis - #BrandCINID', @time OUTPUT

	IF OBJECT_ID('tempdb..#BrandCINID_SelfJoin') IS NOT NULL DROP TABLE #BrandCINID_SelfJoin
	SELECT
	  a.BrandID AS FromBrandID,
	  b.BrandID AS ToBrandID,
	  a.CINID
	INTO #BrandCINID_SelfJoin
	FROM #BrandCINID a
	JOIN #BrandCINID b
	  ON a.CINID = b.CINID

	CREATE CLUSTERED INDEX cix_CINID ON #BrandCINID_SelfJoin (CINID)

	EXEC Warehouse.Prototype.oo_TimerMessage 'Analysis - #BrandCINID_SelfJoin', @time OUTPUT

	IF OBJECT_ID('tempdb..#TranProfile') IS NOT NULL DROP TABLE #TranProfile
	SELECT
	  CINID,
	  BrandID,
	  SUM(CASE WHEN 0 < Amount THEN Amount ELSE 0 END) AS Sales,
	  SUM(CASE WHEN Amount < 0 THEN Amount ELSE 0 END) AS Refund_Sales,
	  COUNT(CASE WHEN 0 < Amount THEN Amount ELSE NULL END) AS Trans,
	  COUNT(CASE WHEN Amount < 0 THEN Amount ELSE NULL END) AS Refund_Trans
	INTO #TranProfile
	FROM #Trans
	GROUP BY
	  CINID,
	  BrandID

	CREATE CLUSTERED INDEX cix_CINID_BrandID ON #TranProfile (CINID, BrandID)

	EXEC Warehouse.Prototype.oo_TimerMessage 'Analysis - #TranProfile', @time OUTPUT

	---------------------------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------------------------
	-- Output

	/* Market Share */
	IF OBJECT_ID('Warehouse.Prototype.Analysis_MarketShare') IS NOT NULL DROP TABLE Warehouse.Prototype.Analysis_MarketShare
	SELECT
	  a.BrandID,
	  b.BrandName,
	  SUM(Amount) AS Brand_Spend,
	  c.TotalSpend,
	  SUM(Amount)/c.TotalSpend AS MarketShare_Spend,
	  COUNT(Amount) AS Brand_Trans,
	  c.TotalTrans,
	  1.0*COUNT(Amount)/c.TotalTrans AS MarketShare_Trans,
	  COUNT(DISTINCT CINID) AS Brand_Customers,
	  c.TotalShoppers,
	  1.0*COUNT(DISTINCT CINID)/c.TotalShoppers AS Market_Penetration
	INTO Warehouse.Prototype.Analysis_MarketShare
	FROM #Trans a
	JOIN #Brand b
	  ON a.BrandID = b.BrandID
	CROSS JOIN
	  (  SELECT
		   SUM(Amount) AS TotalSpend,
		   COUNT(*) AS TotalTrans,
		   COUNT(DISTINCT CINID) AS TotalShoppers
		 FROM #Trans
		 WHERE 0 < Amount	) c
	WHERE 0 < a.Amount
	GROUP BY 
	  a.BrandID,
	  b.BrandName,
	  c.TotalSpend,
	  c.TotalTrans,
	  c.TotalShoppers
	ORDER BY 1

	EXEC Warehouse.Prototype.oo_TimerMessage 'Analysis - Market Share Output', @time OUTPUT

	/* Share of Wallet */

	IF OBJECT_ID('Warehouse.Prototype.Analysis_ShareOfWallet') IS NOT NULL DROP TABLE Warehouse.Prototype.Analysis_ShareOfWallet
	SELECT
	  a.FromBrandID,
	  a.ToBrandID,
	  br.BrandName AS FromBrandName,
	  brb.BrandName AS ToBrandName,
	  COUNT(*) As CINIDCount,
	  SUM(b.Sales) AS FromBrandID_Sales,
	  SUM(b.Refund_Sales) AS FromBrandID_Refund_Sales,
	  SUM(b.Trans) AS FromBrandID_Trans,
	  SUM(b.Refund_Trans) AS FromBrandID_Refund_Trans,
	  SUM(c.Sales) AS ToBrandID_Sales,
	  SUM(c.Refund_Sales) AS ToBrandID_Refund_Sales,
	  SUM(c.Trans) AS ToBrandID_Trans,
	  SUM(c.Refund_Trans) AS ToBrandID_Refund_Trans
	INTO Warehouse.Prototype.Analysis_ShareOfWallet
	FROM #BrandCINID_SelfJoin a
	JOIN #TranProfile b
	  ON a.CINID = b.CINID
	 AND a.FromBrandID = b.BrandID
	JOIN #TranProfile c
	  ON a.CINID = c.CINID
	 AND a.ToBrandID = c.BrandID
	JOIN #Brand br
	  ON a.FromBrandID = br.BrandID
	JOIN #Brand brb
	  ON a.ToBrandID = brb.BrandID
	GROUP BY
	  a.FromBrandID,
	  a.ToBrandID,
	  br.BrandName,
	  brb.BrandName
	ORDER BY 1,2

	EXEC Warehouse.Prototype.oo_TimerMessage 'Analysis - Share Of Wallet Output', @time OUTPUT

	/* Last Visit */
	IF OBJECT_ID('Warehouse.Prototype.Analysis_LastVisit') IS NOT NULL DROP TABLE Warehouse.Prototype.Analysis_LastVisit
	SELECT
	  a.FromBrandID,
	  a.ToBrandID,
	  br.BrandName AS FromBrandName,
	  brb.BrandName AS ToBrandName,
	  COALESCE(b.LastSpend,0) AS FromBrandID_LastSpend,
	  COALESCE(c.LastSpend,0) AS ToBrandID_LastSpend,
	  COUNT(a.CINID) AS Customers
	INTO Warehouse.Prototype.Analysis_LastVisit
	FROM #BrandCINID_SelfJoin a
	LEFT JOIN #SpendByDay b
	  ON a.CINID = b.CINID
	 AND a.FromBrandID = b.BrandID
	 AND b.LastSpend = 1
	LEFT JOIN #SpendByDay c
	  ON a.CINID = c.CINID
	 AND a.ToBrandID = c.BrandID
	 AND c.LastSpend = 1
	JOIN #Brand br
	  ON a.FromBrandID = br.BrandID
	JOIN #Brand brb
	  ON a.ToBrandID = brb.BrandID 
	GROUP BY
	  a.FromBrandID,
	  a.ToBrandID,
	  br.BrandName,
	  brb.BrandName,
	  COALESCE(b.LastSpend,0),
	  COALESCE(c.LastSpend,0)
	ORDER BY
	  1,2,3,4,5,6

	EXEC Warehouse.Prototype.oo_TimerMessage 'Analysis - Last Visit Output', @time OUTPUT
  
	/* Spend Within Locality */

	IF OBJECT_ID('Warehouse.Prototype.Analysis_WithinDriveTime') IS NOT NULL DROP TABLE Warehouse.Prototype.Analysis_WithinDriveTime
	SELECT
	  a.BrandID,
	  b.BrandName,
	  SUM(Amount) AS Brand_Spend,
	  SUM(CASE WHEN WithinDriveTime = 1 THEN Amount ELSE 0 END) AS Local_Brand_Spend,
	  d.MainBrandShoppers_Local_Brand_Spend,
	  c.TotalSpend,

	  COUNT(Amount) AS Brand_Trans,
	  COUNT(CASE WHEN WithinDriveTime = 1 THEN Amount ELSE NULL END) AS Local_Brand_Trans,
	  d.MainBrandShoppers_Local_Brand_Trans,
	  c.TotalTrans,
  
	  COUNT(DISTINCT CINID) AS Brand_Customers,
	  COUNT(DISTINCT CASE WHEN WithinDriveTime = 1 THEN CINID ELSE NULL END) AS Local_Brand_Customers,
	  d.MainBrandShoppers_Local_Brand_Customers,
	  c.TotalShoppers
	INTO Warehouse.Prototype.Analysis_WithinDriveTime
	FROM #Trans a
	JOIN #Brand b
	  ON a.BrandID = b.BrandID
	CROSS JOIN
	  (  SELECT
		   SUM(Amount) AS TotalSpend,
		   COUNT(*) AS TotalTrans,
		   COUNT(DISTINCT CINID) AS TotalShoppers
		 FROM #Trans
		 WHERE 0 < Amount
		   AND WithinDriveTime = 1 ) c
	LEFT JOIN
	  ( SELECT
		  t.BrandID,
		  SUM(Amount) AS MainBrandShoppers_Local_Brand_Spend,
		  COUNT(Amount) AS MainBrandShoppers_Local_Brand_Trans,
		  COUNT(DISTINCT t.CINID) AS MainBrandShoppers_Local_Brand_Customers
		FROM #BrandCINID bc
		JOIN #Trans t
		  ON bc.CINID = t.CINID
		 AND 0 < t.Amount
		 AND t.WithinDriveTime = 1
		WHERE bc.BrandID = @MainBrand
		GROUP BY 
		  t.BrandID
	  ) d
	  ON a.BrandID = d.BrandID
	WHERE 0 < a.Amount
	GROUP BY 
	  a.BrandID,
	  b.BrandName,
	  c.TotalSpend,
	  c.TotalTrans,
	  c.TotalShoppers,
	  d.MainBrandShoppers_Local_Brand_Spend,
	  d.MainBrandShoppers_Local_Brand_Trans,
	  d.MainBrandShoppers_Local_Brand_Customers
	ORDER BY 1

	EXEC Warehouse.Prototype.oo_TimerMessage 'Analysis - Within Drivetime Output', @time OUTPUT

	IF OBJECT_ID('Warehouse.Prototype.Analysis_WithinDriveTime_MainBrandTotal') IS NOT NULL DROP TABLE Warehouse.Prototype.Analysis_WithinDriveTime_MainBrandTotal
	SELECT
		  SUM(Amount) AS MainBrandShoppers_Local_Spend,
		  COUNT(Amount) AS MainBrandShoppers_Local_Trans,
		  COUNT(DISTINCT t.CINID) AS MainBrandShoppers_Local_Customers
	INTO  Warehouse.Prototype.Analysis_WithinDriveTime_MainBrandTotal
		FROM #BrandCINID bc
		JOIN #Trans t
		  ON bc.CINID = t.CINID
		 AND 0 < t.Amount
		 AND t.WithinDriveTime = 1
		WHERE bc.BrandID = @MainBrand


	IF OBJECT_ID('Warehouse.Prototype.Analysis_WithinDriveTime_BrandTotal') IS NOT NULL DROP TABLE Warehouse.Prototype.Analysis_WithinDriveTime_BrandTotal
	SELECT	COUNT(DISTINCT CASE WHEN WithinDriveTime = 1 THEN CINID ELSE NULL END) AS Local_Customers
	INTO	Warehouse.Prototype.Analysis_WithinDriveTime_BrandTotal
	FROM #Trans a
	JOIN #Brand b
	  ON a.BrandID = b.BrandID
	CROSS JOIN
	  (  SELECT
		   SUM(Amount) AS TotalSpend,
		   COUNT(*) AS TotalTrans,
		   COUNT(DISTINCT CINID) AS TotalShoppers
		 FROM #Trans
		 WHERE 0 < Amount
		   AND WithinDriveTime = 1) c

	WHERE 0 < a.Amount
	and b.BrandID <> @MainBrand

	/* Demographic Profiling */

	IF OBJECT_ID('Warehouse.Prototype.Analysis_Demographic') IS NOT NULL DROP TABLE Warehouse.Prototype.Analysis_Demographic
	SELECT
	  a.Gender,
	  a.AgeBand,
	  a.CAMEO,
	  a.BaseDistribution,
	  b.SelectionDistribution,
	  COALESCE(c.BrandName,'Total') AS BrandName,
	  COALESCE(c.Sales,0) AS Sales,
	  COALESCE(c.Trans,0) AS Trans,
	  COALESCE(c.Shoppers,0) AS Shoppers
	INTO Warehouse.Prototype.Analysis_Demographic
	FROM 
		(
			SELECT 
			  AgeBand,Gender,Cameo,
			  COUNT(*) AS BaseDistribution
			FROM #FullBase
			GROUP BY 
			  AgeBand,Gender,Cameo
		) a
	LEFT JOIN 
		(
			SELECT 
			  AgeBand, Gender, Cameo,
			  COUNT(*) AS SelectionDistribution
			FROM #FullBase a
			JOIN #Customer c
			  ON a.CINID = c.CINID
			GROUP BY
			  AgeBand, Gender, Cameo
		) b
	  ON a.AgeBand = b.AgeBand
	 AND a.Gender = b.Gender
	 AND a.Cameo = b.Cameo
	LEFT JOIN
		(
			SELECT
			  AgeBand,Gender,Cameo,
			  BrandName,
			  COALESCE(SUM(Amount),0) AS Sales,
			  COALESCE(COUNT(Amount),0) AS Trans,
			  COUNT(DISTINCT a.CINID) AS Shoppers 
			FROM #FullBase a
			LEFT JOIN #Trans b
			  ON a.CINID = b.CINID
			JOIN #Brand br
			  ON b.BrandID = br.BrandID
			WHERE 0 < b.Amount
			GROUP BY
			  AgeBand, Gender, Cameo,
			  BrandName
			UNION
			SELECT
			  AgeBand,Gender,Cameo,
			  'Total' AS BrandName,
			  COALESCE(SUM(Amount),0) AS Sales,
			  COALESCE(COUNT(Amount),0) AS Trans,
			  COUNT(DISTINCT a.CINID) AS Shoppers 
			FROM #FullBase a
			LEFT JOIN #Trans b
			  ON a.CINID = b.CINID
			JOIN #Brand br
			  ON b.BrandID = br.BrandID
			WHERE 0 < b.Amount
			GROUP BY
			  AgeBand, Gender, Cameo
		) c
	  ON a.AgeBand = c.AgeBand
	 AND a.Gender = c.Gender
	 AND a.CAMEO = c.CAMEO
	ORDER BY 1,2,3

	EXEC Warehouse.Prototype.oo_TimerMessage 'Analysis - Demographic Output', @time OUTPUT
	  
	EXEC Warehouse.Prototype.oo_TimerMessage 'Analysis - Finished', @time OUTPUT

END