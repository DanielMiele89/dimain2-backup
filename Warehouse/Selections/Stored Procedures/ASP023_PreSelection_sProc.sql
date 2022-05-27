
CREATE PROCEDURE [Selections].[ASP023_PreSelection_sProc]
AS
BEGIN

-- RBS Bespoke Code -- 
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
WHERE	BrandID IN (2107,2660,2665,2085,1651)							-- Kate Spade, Mulberry, Coach, Burberry and Smythson

IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	CT.CINID as CINID
		,COUNT(CT.CINID) AS Txn
INTO	#Trans
FROM	Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC CC ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN	#FB F ON F.CINID = CT.CINID
WHERE	TranDate > DATEADD(MONTH, -24, GETDATE())
		AND Amount > 0
GROUP BY CT.CINID


IF OBJECT_ID('Sandbox.LeoP.RBS_Aspinal_CompSteal010422') IS NOT NULL DROP TABLE Sandbox.LeoP.RBS_Aspinal_CompSteal010422


SELECT	CINID
INTO Sandbox.LeoP.RBS_Aspinal_CompSteal010422
FROM  #Trans


	IF OBJECT_ID('[Warehouse].[Selections].[ASP023_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[ASP023_PreSelection]
	SELECT FanID
	INTO [Warehouse].[Selections].[ASP023_PreSelection]
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.LeoP.RBS_Aspinal_CompSteal010422  st
					WHERE fb.CINID = st.CINID)

END
