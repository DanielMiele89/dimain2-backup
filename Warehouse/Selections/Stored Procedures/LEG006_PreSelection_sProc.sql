-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-08-21>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.LEG006_PreSelection_sProcASBEGIN/*

SELECT *
FROM Relational.Brand
WHERE BrandName LIKE '%Lego%' --2089--

*/

DECLARE @MainBrand INT = 2089
	 , @LapsedDateLimit DATE = (SELECT DATEADD(MONTH, -36, GETDATE()))
	 , @ShopperDateLimit DATE = (SELECT DATEADD(MONTH, -12, GETDATE()))

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
	 , cc.BrandID
	 , BrandName
INTO #CC
FROM Relational.ConsumerCombination cc
INNER JOIN Relational.Brand B
	ON B.BrandID = cc.BrandID
WHERE cc.BrandID = @MainBrand

CREATE CLUSTERED INDEX ix_ComboID ON #CC (ConsumerCombinationID)

IF OBJECT_ID('tempdb..#CT') IS NOT NULL DROP TABLE #CT
SELECT ct.CINID
	 , MAX(CASE
	 			WHEN @ShopperDateLimit <= TranDate AND IsOnline = 1 THEN 1
	 			ELSE 0
	 	 END) AS Shopper
	 , MAX(CASE
	 			WHEN TranDate BETWEEN @LapsedDateLimit AND @ShopperDateLimit THEN 1
	 			ELSE 0
	 	 END) AS Lapsed
	 , MAX(CASE
	 			WHEN TranDate > @LapsedDateLimit THEN 1
	 			ELSE 0
	 	 END) as Acquired
INTO #CT
FROM Warehouse.Relational.ConsumerTransaction_MyRewards ct
WHERE 0 < ct.Amount
AND EXISTS (SELECT 1
			FROM #cc cc
			WHERE cc.ConsumerCombinationID = ct.ConsumerCombinationID)
GROUP BY ct.CINID

IF OBJECT_ID('tempdb..#FullBase') IS NOT NULL DROP TABLE #FullBase
SELECT	
 FanID,
 CINID,
 Gender,
 AgeCurrent,
 COALESCE(C.Region, 'Unknown') AS Region,
 ISNULL(CONCAT(cam.CAMEO_CODE_GROUP,'-',ccg.CAMEO_CODE_GROUP_Category), '99 Unknown') AS CAMEO
INTO #FullBase			 		 	 
FROM Warehouse.Relational.Customer C
JOIN Warehouse.Relational.CINList CL ON CL.CIN = C.SourceUID
LEFT JOIN Warehouse.Relational.CAMEO CAM ON CAM.Postcode = C.PostCode
LEFT JOIN Warehouse.Relational.CAMEO_CODE_GROUP CCG ON CCG.CAMEO_CODE_GROUP = CAM.CAMEO_CODE_GROUP
WHERE c.CurrentlyActive = 1
AND	NOT EXISTS (SELECT 1
				FROM Warehouse.Staging.Customer_DuplicateSourceUID dup
				WHERE c.SourceUID = dup.SourceUID
				AND dup.EndDate IS NULL)

CREATE CLUSTERED INDEX cix_CINID ON #FullBase (CINID)

--TRANS--
IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT F.CINID
	 , F.FanID
	 , Shopper
	 , Lapsed
	 , Acquired

INTO #Trans
FROM #FullBase F
LEFT JOIN #CT ct
	ON ct.CINID = F.CINID

--WHERE AgeCurrent BETWEEN 25 AND 54

--SELECT COUNT(*)
--		,SHOPPER
--		,ACQUIRED
--		,LAPSED
--FROM #Trans
--GROUP BY SHOPPER
--		,ACQUIRED
--		,LAPSED


IF OBJECT_ID('Sandbox.SamW.Lego170919') IS NOT NULL DROP TABLE Sandbox.SamW.Lego170919
SELECT	CINID
		,FanID
INTO Sandbox.SamW.Lego170919
FROM #Trans
WHERE Shopper = 1
OR Lapsed = 1
OR Acquired = 0
OR Acquired = 1
OR ACQUIRED IS NULLIf Object_ID('Warehouse.Selections.LEG006_PreSelection') Is Not Null Drop Table Warehouse.Selections.LEG006_PreSelectionSelect FanIDInto Warehouse.Selections.LEG006_PreSelectionFROM  SANDBOX.SAMW.LEGO170919END