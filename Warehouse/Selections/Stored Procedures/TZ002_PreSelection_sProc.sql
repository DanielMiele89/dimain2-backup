-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-02-21>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.TZ002_PreSelection_sProcASBEGIN
IF OBJECT_ID('TEMPDB..#CC') IS NOT NULL DROP TABLE #CC
SELECT	ConsumerCombinationID
INTO	#CC
FROM	Warehouse.Relational.ConsumerCombination
WHERE	BrandID IN (1865,2537,1878,1746,2452,248,151)
CREATE CLUSTERED INDEX CIX_CC ON #CC(ConsumerCombinationID)


IF OBJECT_ID('TEMPDB..#SEGMENT_ASSIGNMENT') IS NOT NULL DROP TABLE #SEGMENT_ASSIGNMENT
SELECT	 A.CINID
		, A.FanID
		, CASE WHEN SALES IS NULL THEN 0 ELSE 1 END AS COMP_SPENDER
INTO	#SEGMENT_ASSIGNMENT
FROM	(
			SELECT	 CIN.CINID
					, C.FanID
			FROM	Warehouse.Relational.Customer C
			JOIN	Warehouse.Relational.CINList CIN
				ON C.SourceUID = CIN.CIN
			WHERE	C.CurrentlyActive = 1 
				OR	C.SourceUID NOT IN (SELECT SourceUID FROM Warehouse.Staging.Customer_DuplicateSourceUID)
		) A
LEFT JOIN 
		(
			SELECT	 CINID
					, SUM(CT.AMOUNT) AS SALES
			FROM	Warehouse.Relational.ConsumerTransaction_MyRewards CT WITH(NOLOCK)
			JOIN	#CC CC
				ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
			WHERE	TranDate >= DATEADD(MONTH,-3,GETDATE())
				AND CT.Amount > 0
			GROUP BY CINID
		) B
	ON A.CINID = B.CINID

	IF OBJECT_ID('SANDBOX.CONAL.TRAVEL_ZOO_18022020') IS NOT NULL DROP TABLE SANDBOX.CONAL.TRAVEL_ZOO_18022020
	SELECT	 CINID
			, FanID
	INTO	SANDBOX.CONAL.TRAVEL_ZOO_18022020
	FROM	#SEGMENT_ASSIGNMENT
	WHERE	COMP_SPENDER = 1If Object_ID('Warehouse.Selections.TZ002_PreSelection') Is Not Null Drop Table Warehouse.Selections.TZ002_PreSelectionSelect FanIDInto Warehouse.Selections.TZ002_PreSelectionFROM SANDBOX.CONAL.TRAVEL_ZOO_18022020END