-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-06-12>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.COH001_PreSelection_sProcASBEGINIF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT br.BrandID,
		br.BrandName,
		cc.ConsumerCombinationID,
		MID
INTO	#CC
FROM	Warehouse.Relational.Brand br
JOIN	Warehouse.Relational.ConsumerCombination cc ON br.BrandID = cc.BrandID
WHERE	br.BrandID in (1666,
					 40,1664,1665,544,78,260,2468,2698,2456,506,1668,23,2436,1077					 
					 )
ORDER BY br.BrandName
CREATE CLUSTERED INDEX ix_ComboID ON #cc(BrandID,ConsumerCombinationID)

DECLARE @MainBrand SMALLINT = 1666	 -- Main Brand	

If Object_ID('tempdb..#SegmentAssignment') IS NOT NULL DROP TABLE #SegmentAssignment
Select cl.CINID,			-- keep CINID and FANID
		cl.fanid,
		MainBrand,
		CasualDining
INTO #SegmentAssignment

FROM (SELECT CL.CINID,
				cu.FanID
	
		FROM warehouse.Relational.Customer cu
		JOIN warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
		WHERE cu.CurrentlyActive = 1
		AND cu.sourceuid NOT IN (SELECT DISTINCT sourceuid FROM Warehouse.Staging.Customer_DuplicateSourceUID )
		AND Region NOT IN ('Scotland','Northern Ireland','Isle of Man','Channel Islands')		
		GROUP BY CL.CINID, cu.FanID) CL

LEFT JOIN (SELECT ct.CINID,
				 SUM(ct.Amount) as Sales,

				 MAX(CASE WHEN cc.brandid = @MainBrand AND '2020-04-01' <= TranDate AND TranDate < GETDATE() 
 						THEN 1 ELSE 0 END) AS MainBrand,

				 MAX(CASE WHEN cc.brandid IN (1666,40,1664,1665,544,78,260,2468,2698,2456,506,1668,23,2436,1077) AND DATEADD(MONTH,-12,GETDATE()) <= TranDate AND TranDate < GETDATE() 
 						THEN 1 ELSE 0 END) AS CasualDining
						 
			FROM Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
			JOIN #CC cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
			
			WHERE 0 < ct.Amount
			AND TranDate >= DATEADD(MONTH,-12,GETDATE())

			GROUP BY ct.CINID) b on cl.CINID = b.CINID

IF OBJECT_ID('Sandbox.Tasfia.Cote_ExcRegionsFoodServices_020620') IS NOT NULL DROP TABLE Sandbox.Tasfia.Cote_ExcRegionsFoodServices_020620
SELECT CINID,
		FanID

INTO Sandbox.Tasfia.Cote_ExcRegionsFoodServices_020620

FROM #SegmentAssignment
WHERE MainBrand = 0 AND CasualDining = 1


If Object_ID('Warehouse.Selections.COH001_PreSelection') Is Not Null Drop Table Warehouse.Selections.COH001_PreSelectionSelect FanIDInto Warehouse.Selections.COH001_PreSelectionFROM  SANDBOX.TASFIA.COTE_EXCREGIONSFOODSERVICES_020620END