CREATE PROCEDURE [Selections].[MAM009_PreSelection_sProc]
AS
BEGIN

--SELECT * FROM Relational.Brand WHERE BrandName LIKE '%Gym%'


IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID, FanID
INTO	#FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 

CREATE CLUSTERED INDEX CIX_CINID ON #FB (CINID)
CREATE NONCLUSTERED INDEX IX_FanID ON #FB (FanID)

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	  CC.ConsumerCombinationID AS ConsumerCombinationID
INTO	#CC 
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (569,227,568,574,2592,402,24)			-- Competitors: Adidas, JD Sports, Nike, Under Armour, Gym Shark, Sports Direct, ASOS in the last 24 months

CREATE CLUSTERED INDEX CIX_ConsumerCombinationID ON #CC (ConsumerCombinationID)

DECLARE @DATE_24 DATE = DATEADD(MONTH, -24, GETDATE())

IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	CT.CINID as CINID
INTO	#Trans
FROM	Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC CC ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN	#FB F ON F.CINID = CT.CINID
WHERE	TranDate > @DATE_24
		AND Amount > 0
GROUP BY CT.CINID


IF OBJECT_ID('Sandbox.RukanK.MMdirect_CompSteal13072021') IS NOT NULL DROP TABLE Sandbox.RukanK.MMdirect_CompSteal13072021		--1,759,837
SELECT	CINID
INTO Sandbox.RukanK.MMdirect_CompSteal13072021
FROM  #Trans

--select count(distinct cinid) from Sandbox.RukanK.MMdirect_CompSteal13072021

If Object_ID('Warehouse.Selections.MAM009_PreSelection') Is Not Null Drop Table Warehouse.Selections.MAM009_PreSelection
Select FanID
Into Warehouse.Selections.MAM009_PreSelection
FROM #FB F
INNER JOIN Sandbox.RukanK.MMdirect_CompSteal13072021 R
ON R.CINID = F.CINID

END