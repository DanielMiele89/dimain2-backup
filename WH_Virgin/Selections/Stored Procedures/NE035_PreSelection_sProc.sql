
CREATE PROCEDURE [Selections].[NE035_PreSelection_sProc]
AS
BEGIN

	IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
	SELECT	CINID
		,	FanID
	INTO	#FB
	FROM	WH_Virgin.Derived.Customer  C
	JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
	WHERE	C.CurrentlyActive = 1
	AND		SourceUID NOT IN (SELECT SourceUID FROM WH_Virgin.Derived.Customer_DuplicateSourceUID) 

	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT ConsumerCombinationID
			,BrandID
	INTO	#CC
	FROM	WH_Virgin.Trans.ConsumerCombination  CC
	WHERE	BrandID IN    (565,2481,1322,2864,1318,1315,1333,1325,1324,2220,2021,1331,1738,1043,1323,3399,1099,1307,1313,1312,2222,918,935,2324,1285,1737,1754,1336,1338,1337,2540)

	IF OBJECT_ID('Sandbox.bastienc.national_express_virgin') IS NOT NULL DROP TABLE Sandbox.bastienc.national_express_virgin
	SELECT	ct.CINID
	INTO Sandbox.bastienc.national_express_virgin
	FROM	WH_Virgin.Trans.ConsumerTransaction CT
	JOIN	#FB F ON F.CINID = CT.CINID
	JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
	WHERE	TranDate > DATEADD(MONTH, -6, GETDATE())
			AND Amount > 0
	GROUP BY ct.CINID

	IF OBJECT_ID('[WH_Virgin].[Selections].[NE035_PreSelection]') IS NOT NULL DROP TABLE [WH_Virgin].[Selections].[NE035_PreSelection]
	SELECT CONVERT(INT, fanID) AS FanID
	INTO [WH_Virgin].[Selections].[NE035_PreSelection]
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.BastienC.national_express_virgin st
					WHERE fb.CINID = st.CINID)

END


