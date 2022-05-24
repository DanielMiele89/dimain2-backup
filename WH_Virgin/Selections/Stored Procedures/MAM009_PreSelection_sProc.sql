-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2020-12-11>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
CREATE PROCEDURE [Selections].[MAM009_PreSelection_sProc]
AS
BEGIN



IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID, FanID
INTO	#FB
FROM	Derived.Customer C
JOIN	Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Derived.Customer_DuplicateSourceUID) 


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	  CC.ConsumerCombinationID AS ConsumerCombinationID
INTO	#CC 
FROM	Trans.ConsumerCombination CC
WHERE	BrandID IN (569,227,568,574,2592,402,24)			-- Competitors: Adidas, JD Sports, Nike, Under Armour, Gym Shark, Sports Direct, ASOS in the last 24 months


IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	CT.CINID as CINID
INTO	#Trans
FROM	Trans.ConsumerTransaction CT
JOIN	#CC CC ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN	#FB F ON F.CINID = CT.CINID
WHERE	TranDate > DATEADD(MONTH, -24, GETDATE())
		AND Amount > 0
GROUP BY CT.CINID


IF OBJECT_ID('Sandbox.RukanK.VM_MMdirect_CompSteal13072021') IS NOT NULL DROP TABLE Sandbox.RukanK.VM_MMdirect_CompSteal13072021		--1,759,837
SELECT	CINID
INTO Sandbox.RukanK.VM_MMdirect_CompSteal13072021
FROM  #Trans

--select count(distinct cinid) from Sandbox.RukanK.MMdirect_CompSteal13072021



If Object_ID('WH_Virgin.Selections.MAM009_PreSelection') Is Not Null Drop Table WH_Virgin.Selections.MAM009_PreSelection
Select FanID
Into WH_Virgin.Selections.MAM009_PreSelection
From #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.RukanK.VM_MMdirect_CompSteal13072021 cs
				WHERE fb.CINID = cs.CINID)


END