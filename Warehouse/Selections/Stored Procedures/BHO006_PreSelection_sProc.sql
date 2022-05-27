CREATE PROCEDURE [Selections].[BHO006_PreSelection_sProc]
AS
BEGIN


IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID, FanID
INTO	#FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 
AND		Gender = 'F'
AND		AgeCurrent BETWEEN 18 AND 55
AND		FanID NOT IN (SELECT FANID
				      FROM Relational.Customer_RBSGSegments	
					  WHERE CustomerSegment = 'V'
							AND EndDate IS NULL)

CREATE CLUSTERED INDEX CIX_CINID ON #FB (CINID)

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT  ConsumerCombinationID
INTO	#CC
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (1610,2019,24,2523,303,2520,2519,187)      
CREATE CLUSTERED INDEX CIX_ConsumerCombinationID ON #CC (ConsumerCombinationID)

DECLARE @DATE DATE =DATEADD(MONTH,-12,GETDATE())

IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	F.CINID
INTO	#Trans
FROM	#FB F
JOIN	Relational.ConsumerTransaction_MyRewards CT ON F.CINID = CT.CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	Amount > 0	AND	TranDate >= @DATE
GROUP BY F.CINID


IF OBJECT_ID('Sandbox.RukanK.boohoo_Female_CompSteal_18to55_09082021') IS NOT NULL DROP TABLE Sandbox.RukanK.boohoo_Female_CompSteal_18to55_09082021
SELECT	CINID
INTO Sandbox.RukanK.boohoo_Female_CompSteal_18to55_09082021
FROM	#Trans
GROUP BY CINID

IF OBJECT_ID('[Warehouse].[Selections].[BHO006_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[BHO006_PreSelection]
SELECT	fb.FanID
INTO [Warehouse].[Selections].[BHO006_PreSelection]
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.RukanK.boohoo_Female_CompSteal_18to55_09082021 sb
				WHERE fb.CINID = sb.CINID)

END;
