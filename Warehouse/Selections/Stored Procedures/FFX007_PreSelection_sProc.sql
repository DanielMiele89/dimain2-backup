CREATE PROCEDURE [Selections].[FFX007_PreSelection_sProc]
AS
BEGIN

					
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
WHERE	BrandID IN (29,204,383,456,469,498,3410,3412,3413,3414,3415,3416,3417,3418,3419,3420,3421,3422,3423,3424,3425,3426,3427,3428,3429,3430,3431,3432)	

CREATE CLUSTERED INDEX CIX_ConsumerCombinationID ON #CC (ConsumerCombinationID)

DECLARE @DATE DATE = DATEADD(MONTH, -24, GETDATE())

IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	CT.CINID as CINID
		,COUNT(CT.CINID) AS Txn
INTO	#Trans
FROM	Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC CC ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN	#FB F ON F.CINID = CT.CINID
WHERE	TranDate > @DATE
		AND Amount > 0
GROUP BY CT.CINID


IF OBJECT_ID('Sandbox.SamH.FFXTools_CompSteal09072021') IS NOT NULL DROP TABLE Sandbox.SamH.FFXTools_CompSteal09072021
SELECT	CINID
INTO Sandbox.SamH.FFXTools_CompSteal09072021
FROM  #Trans
GROUP BY CINID


If Object_ID('Warehouse.Selections.FFX007_PreSelection') Is Not Null Drop Table Warehouse.Selections.FFX007_PreSelection
Select FanID
Into Warehouse.Selections.FFX007_PreSelection
FROM #FB fb
WHERE Exists (select 1 from Sandbox.SamH.FFXTools_CompSteal09072021 cs
where fb.cinid = cs.cinid)



END