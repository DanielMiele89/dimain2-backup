
CREATE PROCEDURE [Selections].[GS009_PreSelection_sProc]
AS
BEGIN

-------------------------------------------------------------------------------------
----Visa
-------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#FB_vm') IS NOT NULL DROP TABLE #FB_vm
SELECT	CINID,FanID
INTO	#FB_VM
FROM	WH_Visa.Derived.Customer  C
JOIN	WH_Visa.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
		AND AccountType IS NOT NULL
		AND AgeCurrent > 35
CREATE CLUSTERED INDEX ix_CINID on #FB_VM(CINID)

IF OBJECT_ID('Sandbox.RukanK.BC_GymShark_age35_14032022') IS NOT NULL DROP TABLE Sandbox.RukanK.BC_GymShark_age35_14032022		-- 176,375
SELECT	CINID
INTO	Sandbox.RukanK.BC_GymShark_age35_14032022
FROM	#FB_VM
GROUP BY CINID

	IF OBJECT_ID('[WH_Visa].[Selections].[GS009_PreSelection]') IS NOT NULL DROP TABLE [WH_Visa].[Selections].[GS009_PreSelection]
	SELECT FanID
	INTO [WH_Visa].[Selections].[GS009_PreSelection]
	FROM #FB_VM fb
	WHERE EXISTS (SELECT 1 FROM Sandbox.RukanK.BC_GymShark_age35_14032022 s WHERE fb.CINID = s.CINID)
	
END

