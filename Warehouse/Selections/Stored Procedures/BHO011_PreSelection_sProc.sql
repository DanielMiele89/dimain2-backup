
CREATE PROCEDURE [Selections].[BHO011_PreSelection_sProc]
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
CREATE CLUSTERED INDEX ix_FanID on #FB(FanID)

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	  CC.ConsumerCombinationID AS ConsumerCombinationID
INTO	#CC 
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (1050)										-- Boohoo.com

IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	FanID
		,COUNT(CT.CINID) AS Txn
INTO	#Trans
FROM	Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC CC ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN	#FB F ON F.CINID = CT.CINID
WHERE	TranDate BETWEEN DATEADD(MONTH, -3, GETDATE()) AND DATEADD(MONTH, -1, GETDATE())
		AND Amount > 0
GROUP BY FanID
CREATE CLUSTERED INDEX ix_FanID on #Trans(FanID)

IF OBJECT_ID('tempdb..#Returns') IS NOT NULL DROP TABLE #Returns
SELECT	FanID
INTO	#Returns
FROM	Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC CC ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN	#FB F ON F.CINID = CT.CINID
WHERE	TranDate > DATEADD(MONTH, -1, GETDATE())
		AND Amount < 0
GROUP BY FanID
CREATE CLUSTERED INDEX ix_FanID on #Returns(FanID)

IF OBJECT_ID('tempdb..#RepeatCust') IS NOT NULL DROP TABLE #RepeatCust
SELECT	FanID
INTO	#RepeatCust
FROM	Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC CC ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN	#FB F ON F.CINID = CT.CINID
WHERE	TranDate > DATEADD(MONTH, -1, GETDATE())
		AND Amount > 0
GROUP BY FanID
CREATE CLUSTERED INDEX ix_FanID on #RepeatCust(FanID)

IF OBJECT_ID('Sandbox.Rukank.Boohoo_Female_Nursery_23022022') IS NOT NULL DROP TABLE Sandbox.Rukank.Boohoo_Female_Nursery_23022022
SELECT	FanID
INTO	Sandbox.Rukank.Boohoo_Female_Nursery_23022022
FROM	#Trans
WHERE	Txn = 1
		AND FanID NOT IN (SELECT FanID FROM #Returns
						  UNION
						  SELECT FanID FROM #RepeatCust
						  );						
							
IF OBJECT_ID('Warehouse.Selections.BHO011_PreSelection') IS NOT NULL DROP TABLE Warehouse.Selections.BHO011_PreSelection
select FanID
into Selections.BHO011_PreSelection
from Sandbox.Rukank.Boohoo_Female_Nursery_23022022							
							
					
							
							

END

