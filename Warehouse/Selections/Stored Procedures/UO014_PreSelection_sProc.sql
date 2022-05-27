CREATE PROCEDURE [Selections].[UO014_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID ,FanID, Region, City
INTO #FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
AND		Region IN ('Northern Ireland','Scotland','West Midlands','East Midlands')
OR		City Like '%Manchester%'
OR		City Like '%Liverpool%'
CREATE CLUSTERED INDEX ix_CINID on #FB(CINID)


IF OBJECT_ID('Sandbox.rukank.UrbanOutfitters25062021') IS NOT NULL DROP TABLE Sandbox.rukank.UrbanOutfitters25062021
SELECT	F.CINID
INTO	Sandbox.rukank.UrbanOutfitters25062021
FROM	#FB F
GROUP BY F.CINID

IF OBJECT_ID('[Warehouse].[Selections].[UO014_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[UO014_PreSelection]
SELECT	FanID
INTO [Warehouse].[Selections].[UO014_PreSelection]
FROM #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.RukanK.UrbanOutfitters25062021 st
				WHERE fb.CINID = st.CINID)

END