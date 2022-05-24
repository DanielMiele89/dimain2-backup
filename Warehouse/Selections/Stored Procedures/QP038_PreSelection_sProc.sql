-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-04-17>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE Procedure Selections.QP038_PreSelection_sProcASBEGINIF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT br.BrandID
	 , br.BrandName
	 , cc.ConsumerCombinationID
INTO #CC
FROM Relational.Brand br
JOIN Relational.ConsumerCombination cc
	ON br.BrandID = cc.BrandID
WHERE br.BrandID IN (361, 15, 1909, 299, 1486)

CREATE CLUSTERED INDEX ix_ComboID ON #cc (BrandID, ConsumerCombinationID)

If Object_ID('tempdb..#CINList') IS NOT NULL DROP TABLE #CINList
SELECT CL.CINID
	 , cu.FanID
INTO #CINList
FROM Relational.Customer cu
JOIN Relational.CINList cl
	ON cu.SourceUID = cl.CIN
WHERE cu.CurrentlyActive = 1
AND cu.SourceUID NOT IN (SELECT DISTINCT SourceUID FROM Staging.Customer_DuplicateSourceUID)
GROUP BY CL.CINID
	   , cu.FanID

DECLARE @MainBrand SMALLINT = 361	 -- Main Brand	
	  , @Today DATETIME = GETDATE()
	  , @LastYear DATETIME = DATEADD(MONTH,-12,GETDATE())
	  , @TwoYearsAgo DATETIME = DATEADD(MONTH,-24,GETDATE())

If Object_ID('tempdb..#Sales') IS NOT NULL DROP TABLE #Sales
SELECT ct.CINID
	 , SUM(ct.Amount) as Sales
	 , MAX(CASE
				WHEN cc.brandid = @MainBrand AND @LastYear <= TranDate AND TranDate < @Today THEN 1
				ELSE 0
		   END) AS MainBrand_Spender
	 , MAX(CASE
				WHEN cc.brandid <> @MainBrand AND @LastYear <= TranDate AND TranDate < @Today THEN 1
				ELSE 0
		   END) AS Comp_Spender
INTO #Sales
FROM Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
JOIN #CC cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
Where 0 < ct.Amount
and @TwoYearsAgo < TranDate
GROUP BY ct.CINID


--Segment Assignment--
If Object_ID('tempdb..#SegmentAssignment') IS NOT NULL DROP TABLE #SegmentAssignment
Select cl.CINID			-- keep CINID and FANID
	 , cl.FanID
INTO #SegmentAssignment
FROM #CINList CL
LEFT JOIN #Sales b
	on cl.CINID = b.CINID
WHERE MainBrand_Spender = 0
AND Comp_Spender = 1

IF OBJECT_ID('Sandbox.Tasfia.QPark_CompSteal_260319') IS NOT NULL DROP TABLE Sandbox.Tasfia.QPark_CompSteal_260319
SELECT CINID
	 , FanID
INTO Sandbox.Tasfia.QPark_CompSteal_260319
FROM #SegmentAssignment

IF OBJECT_ID('Warehouse.Selections.QP038_PreSelection') IS NOT NULL DROP TABLE Warehouse.Selections.QP038_PreSelectionSELECT FanIDINTO Warehouse.Selections.QP038_PreSelectionFROM #segmentAssignmentEND