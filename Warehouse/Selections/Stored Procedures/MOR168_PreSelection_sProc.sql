
CREATE PROCEDURE [Selections].[MOR168_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID,FanID
INTO	#FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		C.SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
GROUP BY CL.CINID,FanID
CREATE CLUSTERED INDEX ix_FanID on #FB(CINID)


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT		ConsumerCombinationID
INTO		#CC
FROM		Relational.ConsumerCombination CC
JOIN		Relational.Brand B ON B.BrandID = CC.BrandID
WHERE		SectorID  IN  (20,70)											-- Sectors: Food Delivery Services, Grocery Delivery
GROUP BY	ConsumerCombinationID
CREATE CLUSTERED INDEX ix_ConsumerCombinationID on #CC(ConsumerCombinationID)


IF OBJECT_ID('tempdb..#Txn') IS NOT NULL DROP TABLE #Txn					-- 1,205,230
SELECT  CT.CINID as CINID
INTO	#Txn
FROM	Relational.ConsumerTransaction_MyRewards CT	
JOIN	#CC CC ON CC.ConsumerCombinationID = CT.ConsumerCombinationID
JOIN	#FB FB	ON CT.CINID = FB.CINID
WHERE	TranDate >= DATEADD(MONTH,-6,GETDATE()) 
GROUP BY CT.CINID
CREATE CLUSTERED INDEX ix_CINID on #Txn(CINID)



IF OBJECT_ID('Sandbox.RukanK.Morrisons_ImmediateDelivery_06052022') IS NOT NULL DROP TABLE Sandbox.RukanK.Morrisons_ImmediateDelivery_06052022
SELECT	CINID
INTO	Sandbox.RukanK.Morrisons_ImmediateDelivery_06052022
FROM	#Txn
GROUP BY CINID
	

	IF OBJECT_ID('[Warehouse].[Selections].[MOR168_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[MOR168_PreSelection]
	SELECT FanID
	INTO [Warehouse].[Selections].[MOR168_PreSelection]
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.RukanK.Morrisons_ImmediateDelivery_06052022  st
					WHERE fb.CINID = st.CINID)

END