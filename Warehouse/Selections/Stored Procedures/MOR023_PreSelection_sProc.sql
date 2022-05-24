-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-05-02>-- Description: < sProc to run preSelection code per camapign >-- =============================================Create Procedure Selections.MOR023_PreSelection_sProcASBEGIN
/*

SELECT *
FROM Relational.Brand
WHERE SectorID = 3

*/


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT br.brandid
	 , cc.ConsumerCombinationID
INTO #CC
FROM Relational.Brand br
INNER JOIN Warehouse.Relational.ConsumerCombination cc
	ON br.BrandID = cc.BrandID
WHERE SectorID = 3

CREATE CLUSTERED INDEX ix_ComboID ON #cc (ConsumerCombinationID)

IF OBJECT_ID('tempdb..#PostcodeSector') IS NOT NULL DROP TABLE #PostcodeSector
SELECT Postcode_Sector
INTO #PostcodeSector
FROM (SELECT Postal_sector AS Postcode_Sector 
	  FROM [Sandbox].[Conal].[Live_Postcodes_one_column]
	  UNION
	  SELECT Postcode_Sector 
	  FROM [Sandbox].[Conal].[Store_Pick_postcode_sectors_190228]) a
	 


--if needed to do SoW
DECLARE @MainBrand SMALLINT = 292	 -- Main Brand	
	  , @TranDate DATE = DATEADD(month, -12, GETDATE())
	  , @TranDate_MainBrand DATE = DATEADD(month, -6, GETDATE())


IF OBJECT_ID('tempdb..#Customer') IS NOT NULL DROP TABLE #Customer
SELECT DISTINCT
	   CL.CINID
	 , cu.FanID
	 , cu.AgeCurrent
	 , CASE WHEN p.Postcode_Sector IS NOT NULL THEN 1 ELSE 0 END AS StorePick
	 , CASE WHEN E.Postcode_Sector IS NOT NULL THEN 1 ELSE 0 END AS Erith
	 , CASE WHEN mc.FanID IS NOT NULL THEN 1 ELSE 0 END AS IsMore_card_holder
INTO #Customer
FROM Relational.Customer cu
INNER JOIN Relational.CINList cl
	ON cu.SourceUID = cl.CIN
LEFT JOIN #PostcodeSector p
	ON p.postcode_sector = cu.PostalSector
LEFT JOIN [Sandbox].[Conal].[Erith_Postcode_Sectors_190228] E
	ON E.postcode_sector = cu.PostalSector
LEFT JOIN [InsightArchive].[MorrisonsReward_MatchedCustomers_20190304] mc
	ON mc.FanID = cu.FanID 
WHERE cu.CurrentlyActive = 1
AND NOT EXISTS (SELECT 1
				FROM Staging.Customer_DuplicateSourceUID dps
				WHERE cu.SourceUID = dps.SourceUID)


IF OBJECT_ID('tempdb..#ConsumerTransaction_MyRewards') IS NOT NULL DROP TABLE #ConsumerTransaction_MyRewards
SELECT ct.CINID
	 , MAX(CASE
				WHEN IsOnline = 1 THEN 1
				ELSE 0
		   END) AS OnlineSpender
	 , MAX(CASE
				WHEN cc.BrandID = @MainBrand AND TranDate > @TranDate_MainBrand THEN 1
				ELSE 0
		   END) AS MainBrand_Spender_6m
	 , MAX(CASE
				WHEN cc.brandid = @MainBrand AND TranDate > @TranDate_MainBrand AND IsOnline = 1 THEN 1
				ELSE 0
		   END) AS MainBrand_OnlineSpender_6m
INTO #ConsumerTransaction_MyRewards
FROM Relational.ConsumerTransaction_MyRewards ct
INNER JOIN #cc cc
	ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
WHERE 0 < ct.Amount
AND @TranDate < TranDate
GROUP BY ct.CINID


--		Assign Shopper segments
IF OBJECT_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment
SELECT cu.CINID
	 , cu.FanID
	 , cu.StorePick 
	 , cu.Erith 
	 , cu.ISMore_card_holder
	 , cu.AgeCurrent
	 , COALESCE(ct.MainBrand_OnlineSpender_6m, 0) AS MainBrand_OnlineSpender_6m
	 , COALESCE(ct.MainBrand_Spender_6m, 0) AS MainBrand_Spender_6m
	 , COALESCE(ct.OnlineSpender, 0) AS OnlineSpender
INTO #segmentAssignment
FROM #Customer cu
LEFT JOIN #ConsumerTransaction_MyRewards ct
	ON cu.CINID = ct.CINID
If Object_ID('Warehouse.Selections.MOR023_PreSelection') Is Not Null Drop Table Warehouse.Selections.MOR023_PreSelectionSELECT FanIDINTO Warehouse.Selections.MOR023_PreSelectionFROM #segmentAssignment
WHERE Erith = 1
AND (OnlineSpender = 1 OR MainBrand_Spender_6m = 1 OR AgeCurrent > 50)END