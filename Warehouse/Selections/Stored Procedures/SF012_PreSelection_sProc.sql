
CREATE PROCEDURE [Selections].[SF012_PreSelection_sProc]
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

	IF OBJECT_ID('[Warehouse].[Selections].[SF012_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[SF012_PreSelection]
	SELECT FanID
	INTO [Warehouse].[Selections].[SF012_PreSelection]
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.MichaelM.Stitchfix_CompSteal_23092021  st
					WHERE fb.CINID = st.CINID)

END
