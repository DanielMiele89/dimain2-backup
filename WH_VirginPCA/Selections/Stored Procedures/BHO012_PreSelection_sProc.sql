
CREATE PROCEDURE [Selections].[BHO012_PreSelection_sProc]
AS
BEGIN

-- Total cardholder volume for all segments: 41,623
IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID, FanID
INTO	#FB
FROM	WH_VirginPCA.Derived.Customer  C
JOIN	WH_VirginPCA.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
and AccountType IS NOT NULL
AND		Gender = 'M'
CREATE CLUSTERED INDEX ix_CINID on #FB(CINID)

IF OBJECT_ID('Sandbox.RukanK.VM_PCA_boohooman17032022') IS NOT NULL DROP TABLE Sandbox.RukanK.VM_PCA_boohooman17032022
SELECT	CINID
INTO	Sandbox.RukanK.VM_PCA_boohooman17032022
FROM	#FB

	IF OBJECT_ID('[WH_VirginPCA].[Selections].[BHO012_PreSelection]') IS NOT NULL DROP TABLE [WH_VirginPCA].[Selections].[BHO012_PreSelection]
	SELECT FanID
	INTO [WH_VirginPCA].[Selections].[BHO012_PreSelection]
	FROM #FB fb
	WHERE EXISTS (SELECT 1 FROM Sandbox.RukanK.VM_PCA_boohooman17032022 s WHERE fb.CINID = s.CINID)

END

