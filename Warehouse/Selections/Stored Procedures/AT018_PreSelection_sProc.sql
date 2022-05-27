-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-09-06>-- Description: < sProc to run preselection code per camapign >-- =============================================Create Procedure Selections.AT018_PreSelection_sProcASBEGIN
IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT br.BrandID,
br.BrandName,
cc.ConsumerCombinationID

INTO	#CC

FROM	Warehouse.Relational.Brand br
JOIN	Warehouse.Relational.ConsumerCombination cc ON br.BrandID = cc.BrandID

WHERE	br.BrandID in (1463, --ATG--
1464 , 2004, 2003 , 2002) --Competitors--

ORDER BY br.BrandName

CREATE CLUSTERED INDEX ix_ComboID ON #cc(BrandID,ConsumerCombinationID)


DECLARE @MainBrand SMALLINT = 1463	 -- Main Brand	

--Segment Assignment--
If Object_ID('tempdb..#SegmentAssignment') IS NOT NULL DROP TABLE #SegmentAssignment
Select cl.CINID,			-- keep CINID and FANID
cl.fanid,
MainBrand_Spender,
Comp_Spender

INTO #SegmentAssignment

FROM (SELECT CL.CINID,
cu.FanID
	
FROM warehouse.Relational.Customer cu
JOIN warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN

WHERE cu.CurrentlyActive = 1
AND cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )

GROUP BY CL.CINID, cu.FanID) CL

LEFT JOIN (SELECT ct.CINID,
SUM(ct.Amount) as Sales,

MAX(CASE WHEN cc.brandid = @MainBrand AND DATEADD(WEEK,-112,GETDATE()) < TranDate AND TranDate < GETDATE()
THEN 1 ELSE 0 END) AS MainBrand_Spender,

MAX(CASE WHEN cc.brandid IN (1464 , 2004, 2003 , 2002) AND DATEADD(WEEK,-112,GETDATE()) < TranDate AND TranDate < GETDATE()
THEN 1 ELSE 0 END) AS Comp_Spender

						 
FROM Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
JOIN #CC cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
			
Where		0 < ct.Amount
and TranDate > dateadd(WEEK,-112,getdate())

GROUP BY ct.CINID) b on cl.CINID = b.CINID


IF OBJECT_ID('Sandbox.Tasfia.ATG_CompSteal_200219') IS NOT NULL DROP TABLE Sandbox.Tasfia.ATG_CompSteal_200219
SELECT CINID,
	 FanID
	 INTO Sandbox.Tasfia.ATG_CompSteal_200219
FROM #SegmentAssignment

WHERE MainBrand_Spender = 0
AND Comp_Spender = 1If Object_ID('Warehouse.Selections.AT018_PreSelection') Is Not Null Drop Table Warehouse.Selections.AT018_PreSelectionSelect FanIDInto Warehouse.Selections.AT018_PreSelectionFrom #segmentAssignment
WHERE MainBrand_Spender = 0
AND Comp_Spender = 1END