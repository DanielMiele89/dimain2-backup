-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-04-17>-- Description: < sProc to run preselection code per camapign >-- =============================================Create Procedure Selections.BU008_PreSelection_sProcASBEGINIF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT br.BrandID
	 , br.BrandName
	 , cc.ConsumerCombinationID
INTO	#CC
FROM	Warehouse.Relational.Brand br
JOIN	Warehouse.Relational.ConsumerCombination cc on br.BrandID = cc.BrandID
WHERE	br.BrandID IN (1168)
ORDER BY br.BrandName
CREATE CLUSTERED INDEX ix_ComboID ON #CC(ConsumerCombinationID)

--Segment Assignment--
If Object_ID('tempdb..#SegmentAssignment') IS NOT NULL DROP TABLE #SegmentAssignment
Select cl.CINID			-- keep CINID and FANID
	 , cl.fanid
INTO #SegmentAssignment
FROM (SELECT CL.CINID,
c.FanID
	
FROM warehouse.Relational.Customer c
JOIN warehouse.Relational.CINList cl on c.SourceUID = cl.CIN
JOIN Warehouse.Relational.CAMEO cameo ON c.Postcode = cameo.Postcode
JOIN Relational.Customer_RBSGSegments cs with (nolock) on c.FanID = cs.FanID
WHERE
c.CurrentlyActive = 1 --Cardholders Sandbox--
--c.ActivatedDate < '2018-04-26' --Natural Sales Sandbox--
--AND (c.DeactivatedDate IS NULL OR c.DeactivatedDate >= '2018-04-26') --Natural Sales Sandbox--
AND c.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
AND ((MarketableByEmail = 1 AND CustomerSegment <> 'V') OR CAMEO_CODE_GROUP IN ('05','06','07','08','09','10'))
GROUP BY CL.CINID,
c.FanID) CL

IF OBJECT_ID('Sandbox.Tasfia.Butlins_CAMEOMarkExcPremiumCH') IS NOT NULL DROP TABLE Sandbox.Tasfia.Butlins_CAMEOMarkExcPremiumCH
SELECT CINID,
FanID
INTO Sandbox.Tasfia.Butlins_CAMEOMarkExcPremiumCH
FROM #SegmentAssignmentIf Object_ID('Warehouse.Selections.BU008_PreSelection') Is Not Null Drop Table Warehouse.Selections.BU008_PreSelectionSelect FanIDInto Warehouse.Selections.BU008_PreSelectionFrom #segmentAssignmentEND