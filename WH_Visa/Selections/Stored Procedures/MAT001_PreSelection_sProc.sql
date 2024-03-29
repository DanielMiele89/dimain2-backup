﻿
CREATE PROCEDURE [Selections].[MAT001_PreSelection_sProc]
AS
BEGIN

DROP TABLE if exists #CAMEO
SELECT DISTINCT
cam.CAMEO_CODE
, camc.Social_Class
INTO #CAMEO
FROM Warehouse.Relational.CAMEO cam
JOIN Warehouse.Relational.CAMEO_CODE_GROUP camc on cam.cameo_code_group = camc.cameo_code_group


DROP TABLE if exists #FB
SELECT CINID, Social_Class, FanID
INTO #FB
FROM Derived.Customer C
JOIN Derived.CINList CL ON CL.CIN = C.SourceUID
JOIN #CAMEO cam on c.CAMEOCode = cam.CAMEO_CODE
WHERE C.CurrentlyActive = 1
AND SourceUID NOT IN (SELECT SourceUID FROM Derived.Customer_DuplicateSourceUID)

IF OBJECT_ID('Sandbox.Rukank.MatchesFashion_Cameo_13042022Visa') IS NOT NULL DROP TABLE Sandbox.Rukank.MatchesFashion_Cameo_13042022Visa		-- 2,885,066
SELECT	CINID
INTO	Sandbox.Rukank.MatchesFashion_Cameo_13042022Visa
FROM	#FB
WHERE	Social_Class IN ('AB','C1','C2')


	IF OBJECT_ID('[WH_Visa].[Selections].[MAT001_PreSelection]') IS NOT NULL DROP TABLE [WH_Visa].[Selections].[MAT001_PreSelection]
	SELECT FanID
	INTO [WH_Visa].[Selections].[MAT001_PreSelection]
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.Rukank.MatchesFashion_Cameo_13042022Visa  st
					WHERE fb.CINID = st.CINID)

END

