﻿
CREATE PROCEDURE [Selections].[GS009_PreSelection_sProc]
AS
BEGIN

-------------------------------------------------------------------------------------
----VIRGIN
-------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#FB_vm') IS NOT NULL DROP TABLE #FB_vm
SELECT	CINID,FanID
INTO	#FB_VM
FROM	WH_Virgin.Derived.Customer  C
JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
		AND AccountType IS NOT NULL
		AND AgeCurrent > 35
CREATE CLUSTERED INDEX ix_CINID on #FB_VM(CINID)

IF OBJECT_ID('Sandbox.RukanK.VM_GymShark_age35_14032022') IS NOT NULL DROP TABLE Sandbox.RukanK.VM_GymShark_age35_14032022		-- 176,375
SELECT	#FB_VM.[CINID]
INTO	Sandbox.RukanK.VM_GymShark_age35_14032022
FROM	#FB_VM
GROUP BY #FB_VM.[CINID]

	IF OBJECT_ID('[WH_Virgin].[Selections].[GS009_PreSelection]') IS NOT NULL DROP TABLE [WH_Virgin].[Selections].[GS009_PreSelection]
	SELECT [fb].[FanID]
	INTO [WH_Virgin].[Selections].[GS009_PreSelection]
	FROM #FB_VM fb
	WHERE EXISTS (SELECT 1 FROM Sandbox.RukanK.VM_GymShark_age35_14032022 s WHERE fb.CINID = #FB_VM.[s].CINID)
	
END

