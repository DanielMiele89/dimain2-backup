
CREATE PROCEDURE [Selections].[AT043_PreSelection_sProc]
AS
BEGIN


	IF OBJECT_ID('tempdb..#FB_vm') IS NOT NULL DROP TABLE #FB_vm
SELECT	CINID,FanID
INTO	#FB_VM
FROM	WH_Virgin.Derived.Customer  C
JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
		AND AccountType IS NOT NULL
AND		Region IN ('London','South East')
CREATE CLUSTERED INDEX ix_CINID on #FB_VM(CINID)

IF OBJECT_ID('Sandbox.RukanK.VM_AmbassadorTG_17032022') IS NOT NULL DROP TABLE Sandbox.RukanK.VM_AmbassadorTG_17032022			-- 69,834
SELECT	CINID
INTO	Sandbox.RukanK.VM_AmbassadorTG_17032022
FROM	#FB_VM
GROUP BY CINID

	IF OBJECT_ID('[WH_Virgin].[Selections].[AT043_PreSelection]') IS NOT NULL DROP TABLE [WH_Virgin].[Selections].[AT043_PreSelection]
	SELECT FanID
	INTO [WH_Virgin].[Selections].[AT043_PreSelection]
	FROM #FB_VM fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.RukanK.VM_AmbassadorTG_17032022  st
					WHERE fb.CINID = st.CINID)

END
