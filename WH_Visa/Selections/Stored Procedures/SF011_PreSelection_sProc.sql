CREATE PROCEDURE [Selections].[SF011_PreSelection_sProc] AS BEGIN IF OBJECT_ID('[WH_Visa].[Selections].[SF011_PreSelection]') IS NOT NULL DROP TABLE [WH_Visa].[Selections].[SF011_PreSelection] 
--SELECT CONVERT(INT, 0) AS FanID INTO [WH_Visa].[Selections].[SF011_PreSelection] WHERE 1 = 2 END



IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO	#FB
FROM	WH_Visa.Derived.Customer  C
JOIN	WH_Visa.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
--AND		SourceUID NOT IN (SELECT SourceUID FROM Derived.Customer_DuplicateSourceUID) 


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
INTO	#CC
FROM	WH_Visa.Trans.ConsumerCombination  CC
WHERE	BrandID IN (2868,2867)						-- Competitors:  Lookiero, Thread


IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
INTO	#Trans
FROM	WH_Visa.Trans.Consumertransaction CT
JOIN	#FB F ON F.CINID = CT.CINID
JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate > DATEADD(MONTH, -6, GETDATE())
		AND Amount > 0
GROUP BY F.CINID


IF OBJECT_ID('Sandbox.MichaelM.Stitchfix_Barclays_CompSteal_23092021') IS NOT NULL DROP TABLE Sandbox.MichaelM.Stitchfix_Barclays_CompSteal_23092021
SELECT	CINID
INTO Sandbox.MichaelM.Stitchfix_Barclays_CompSteal_23092021
FROM  #Trans


If Object_ID('Selections.SF011_PreSelection') Is Not Null Drop Table Selections.SF011_PreSelection
Select FanID
Into Selections.SF011_PreSelection
FROM #FB F
INNER JOIN Sandbox.MichaelM.Stitchfix_Barclays_CompSteal_23092021 R
ON R.CINID = F.CINID

END


