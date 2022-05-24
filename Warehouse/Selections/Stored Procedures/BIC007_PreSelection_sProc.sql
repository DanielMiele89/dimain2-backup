
CREATE PROCEDURE [Selections].[BIC007_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT CINID, FanID
,ISNULL((cam.[CAMEO_CODE_GROUP] +'-'+ camg.CAMEO_CODE_GROUP_Category),'99. Unknown') as CAMEO
INTO #FB
FROM Relational.Customer C
JOIN Relational.CINList CL ON CL.CIN = C.SourceUID
LEFT JOIN Relational.CAMEO cam with (nolock) on cam.postcode = c.postcode
LEFT JOIN Relational.CAMEO_CODE_GROUP camG with (nolock) on camG.CAMEO_CODE_GROUP =cam.CAMEO_CODE_GROUP
WHERE C.CurrentlyActive = 1
AND SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
CREATE CLUSTERED INDEX cix_CINID ON #FB(CINID)


IF OBJECT_ID('Sandbox.SamH.bicestercameoBE161221') IS NOT NULL DROP TABLE Sandbox.SamH.bicestercameoBE161221
SELECT CINID
INTO Sandbox.SamH.bicestercameoBE161221
FROM #FB
WHERE CAMEO = '01-Business Elite'
GROUP BY CINID


	IF OBJECT_ID('[Warehouse].[Selections].[BIC007_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[BIC007_PreSelection]
	SELECT FanID
	INTO [Warehouse].[Selections].[BIC007_PreSelection]
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.SamH.bicestercameoBE161221  st
					WHERE fb.CINID = st.CINID)

END

