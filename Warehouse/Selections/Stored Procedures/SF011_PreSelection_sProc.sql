CREATE PROCEDURE [Selections].[SF011_PreSelection_sProc] AS BEGIN IF OBJECT_ID('[Warehouse].[Selections].[SF011_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[SF011_PreSelection] 
--SELECT CONVERT(INT, 0) AS FanID INTO [Warehouse].[Selections].[SF011_PreSelection] WHERE 1 = 2 END



IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID, FanID
INTO	#FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	  CC.ConsumerCombinationID AS ConsumerCombinationID
INTO	#CC 
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (2868,2867)			-- Competitors: Lookiero, Thread
																

IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	CT.CINID as CINID
INTO	#Trans
FROM	Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC CC ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN	#FB F ON F.CINID = CT.CINID
WHERE	TranDate > DATEADD(MONTH, -6, GETDATE())
		AND Amount > 0
GROUP BY CT.CINID



IF OBJECT_ID('Sandbox.MichaelM.Stitchfix_CompSteal_23092021') IS NOT NULL DROP TABLE Sandbox.MichaelM.Stitchfix_CompSteal_23092021
SELECT	CINID
INTO Sandbox.MichaelM.Stitchfix_CompSteal_23092021
FROM  #Trans


If Object_ID('Warehouse.Selections.SF011_PreSelection') Is Not Null Drop Table Warehouse.Selections.SF011_PreSelection
Select FanID
Into Warehouse.Selections.SF011_PreSelection
FROM #FB F
INNER JOIN Sandbox.MichaelM.Stitchfix_CompSteal_23092021 R
ON R.CINID = F.CINID


end

