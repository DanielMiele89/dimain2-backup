-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-08-09>-- Description: < sProc to run preselection code per camapign >-- =============================================Create Procedure Selections.CN105_PreSelection_sProcASBEGINIF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT br.BrandID,
		br.BrandName,
		cc.ConsumerCombinationID
INTO	#CC
FROM	Warehouse.Relational.Brand br
JOIN	Warehouse.Relational.ConsumerCombination cc ON br.BrandID = cc.BrandID
WHERE	br.BrandID in (75, 101, 354, 407, 1085)
ORDER BY br.BrandName
CREATE CLUSTERED INDEX ix_ComboID ON #cc(BrandID,ConsumerCombinationID)


DECLARE @MainBrand SMALLINT = 75	 -- Main Brand	
If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment
SELECT x.*,
		CASE WHEN SOW IS NULL THEN 'Cell 03.0-33.33%'
			 WHEN SOW <= 0.3333	THEN 'Cell 03.0-33.33%'
			 WHEN SOW <= 0.6666	THEN 'Cell 04.33.34-66.66%'
			 WHEN SOW > 0.6666	THEN 'Cell 05.66.67-100%'
		ELSE 'Cell 00.Error' END AS Flag	
INTO #SegmentAssignment
FROM (SELECT cl.CINID,
				cl.fanid,
				Brands,
				Sales,
				MainBrand_sales,
				Comp_sales,
				Trans,
				MainBrand_Trans,
				Comp_Trans,
				MainBrand_Spender_6M,
				MainBrand_Spender_12M,
				Comp_Spender_12M,
				Comp_Spender_6M,
				CAST(MainBrand_Sales AS FLOAT) / CAST(Sales AS FLOAT) AS SOW,
				ROUND(CEILING(CAST(MainBrand_Sales AS FLOAT) / CAST(Sales AS FLOAT)*100),-1) AS SOW_rnd 
		 FROM	(SELECT CL.CINID,
						cu.FanID
				 FROM warehouse.Relational.Customer cu
				 JOIN warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
				 WHERE cu.CurrentlyActive = 1
				 AND cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
				 GROUP BY CL.CINID, cu.FanID
				) CL

LEFT JOIN (SELECT ct.CINID,
				 SUM(ct.Amount) AS Sales,
				 MAX(CASE WHEN cc.brandid = @MainBrand
 							THEN 1 ELSE 0 END) AS MainBrand_Spender_12M,
				 MAX(CASE WHEN cc.brandid <> @MainBrand
							THEN 1 ELSE 0 END) AS Comp_Spender_12M,
				 MAX(CASE WHEN cc.brandid = @MainBrand AND TranDate > DATEADD(MONTH,-6,GETDATE())
							THEN 1 ELSE 0 END) AS MainBrand_Spender_6M,
				 MAX(CASE WHEN cc.brandid <> @MainBrand AND TranDate > DATEADD(MONTH,-6,GETDATE())
 							THEN 1 ELSE 0 END) AS Comp_Spender_6M,							
				 COUNT(DISTINCT brandid) AS Brands,
				 SUM(CASE WHEN cc.brandid = @MainBrand			
							THEN ct.Amount ELSE 0 END) AS MainBrand_Sales,				 
				 SUM(CASE WHEN cc.brandid <> @MainBrand			
							THEN ct.Amount ELSE 0 END) AS Comp_Sales,					
				 COUNT(1) AS Trans,
				 SUM(CASE WHEN cc.brandid = @MainBrand			
							THEN 1 ELSE 0 END) AS MainBrand_Trans,
				 SUM(CASE WHEN cc.brandid <> @MainBrand			
							THEN 1 ELSE 0 END) AS Comp_Trans															
					FROM Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
					JOIN #CC cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
					WHERE 0 < ct.Amount
					AND TranDate > DATEADD(YEAR,-1,GETDATE())
					GROUP BY ct.CINID ) b
	ON cl.CINID = b.CINID
	) x


If Object_ID('tempdb..#ALS') IS NOT NULL DROP TABLE #ALS
SELECT CINID,
		FANID,
		CASE WHEN Comp_Trans >= 8 AND	MainBrand_Trans = 0 THEN 1 ELSE 0 END AS 'Acquired',
		CASE WHEN MainBrand_Trans >= 2 AND Flag = 'Cell 04.33.34-66.66%' THEN 1 ELSE 0 END AS 'Lapsed',
		CASE WHEN Flag = 'Cell 03.0-33.33%' AND MainBrand_Trans >= 8 THEN 1 ELSE 0 END AS 'Shopper'
INTO #ALS
FROM #SegmentAssignment

--ALS--
IF OBJECT_ID('Sandbox.Tasfia.Caffe_Nero_ALS_140219') IS NOT NULL DROP TABLE Sandbox.Tasfia.Caffe_Nero_ALS_140219
SELECT CINID,
		Fanid

INTO Sandbox.Tasfia.Caffe_Nero_ALS_140219

FROM #ALS

WHERE (Acquired = 1 OR Lapsed = 1 OR Shopper = 1)If Object_ID('Warehouse.Selections.CN105_PreSelection') Is Not Null Drop Table Warehouse.Selections.CN105_PreSelectionSelect FanIDInto Warehouse.Selections.CN105_PreSelectionFrom Sandbox.Tasfia.Caffe_Nero_ALS_140219END