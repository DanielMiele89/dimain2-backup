CREATE PROCEDURE [Selections].[BU014_PreSelection_sProc]
AS
BEGIN

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
WHERE	BrandID IN (2625,1504,1093,1495)			-- Competitors: Park Holidays, Parkdean Resorts, Cener Parcs and Haven, 
																
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



IF OBJECT_ID('Sandbox.MichaelM.Butlins_CompSteal_17092021') IS NOT NULL DROP TABLE Sandbox.MichaelM.Butlins_CompSteal_17092021
SELECT	CINID
INTO Sandbox.MichaelM.Butlins_CompSteal_17092021
FROM  #Trans				


IF OBJECT_ID('[Warehouse].[Selections].[BU014_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[BU014_PreSelection]
SELECT FanID
INTO [Warehouse].[Selections].[BU014_PreSelection]
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.MichaelM.Butlins_CompSteal_17092021 sb
				WHERE fb.CINID = sb.CINID)

END
