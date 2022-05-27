
CREATE PROCEDURE [Selections].[BIC010_PreSelection_sProc]
AS
BEGIN


IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT cl.CINID, c.FanID
,Classification, Engagement_Score
		,CASE WHEN Classification = 'Gold' THEN 1
			  WHEN Classification = 'Silver' THEN 2
			  WHEN Classification = 'Bronze' THEN 3
			  WHEN Classification = 'Blue' THEN 4
			 ELSE 5
		END AS Classification_Score
INTO #FB
FROM Relational.Customer C
JOIN Relational.CINList CL ON CL.CIN = C.SourceUID
LEFT JOIN Relational.CAMEO cam with (nolock) on cam.postcode = c.postcode
LEFT JOIN Relational.CAMEO_CODE_GROUP camG with (nolock) on camG.CAMEO_CODE_GROUP =cam.CAMEO_CODE_GROUP
LEFT JOIN InsightArchive.EngagementScore E ON E.FanID = C.FanID
WHERE C.CurrentlyActive = 1
AND c.SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 
--AND camg.CAMEO_CODE_GROUP_Category NOT IN ('Business Elite','Content Communities','Flourishing Society','Prosperous Professionals')	-- Updated to the below for 2nd June
AND camg.CAMEO_CODE_GROUP_Category NOT IN ('Business Elite','Prosperous Professionals')
CREATE CLUSTERED INDEX cix_CINID ON #FB(CINID)

IF OBJECT_ID('tempdb..#NtileEngaged') IS NOT NULL DROP TABLE #NtileEngaged		-- to get 20% of the most engaged customers = 5 tiles, pick 1
SELECT	  CINID, Classification, Classification_Score, Engagement_Score
		, NTILE(4) OVER (ORDER BY Classification_Score ASC, Engagement_Score DESC) AS NTILE_4
INTO	#NtileEngaged
FROM	#FB T 


IF OBJECT_ID('Sandbox.SamH.BicesterABupper2517122021') IS NOT NULL DROP TABLE Sandbox.SamH.BicesterABupper2517122021
SELECT	CINID
INTO	Sandbox.SamH.BicesterABupper2517122021
FROM	#NtileEngaged
WHERE	NTILE_4 IN (1)
GROUP BY CINID
	


	IF OBJECT_ID('[Warehouse].[Selections].[BIC010_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[BIC010_PreSelection]
	SELECT FanID
	INTO [Warehouse].[Selections].[BIC010_PreSelection]
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.SamH.BicesterABupper2517122021  st
					WHERE fb.CINID = st.CINID)

END