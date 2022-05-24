
CREATE PROCEDURE [Selections].[BHO010_PreSelection_sProc]
AS
BEGIN


IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID,FanID
INTO	#FB
FROM	WH_Virgin.Derived.Customer  C
JOIN	WH_Virgin.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
and AccountType IS NOT NULL
AND		SourceUID NOT IN (SELECT [Derived].[Customer_DuplicateSourceUID].[SourceUID] FROM Derived.Customer_DuplicateSourceUID) 
AND		Gender = 'M'
CREATE CLUSTERED INDEX ix_CINID on #FB(CINID)


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT [WH_Virgin].[trans].[ConsumerCombination].[ConsumerCombinationID]
INTO	#CC
FROM	WH_Virgin.trans.ConsumerCombination  CC
WHERE	[WH_Virgin].[trans].[ConsumerCombination].[BrandID] IN (31,113,161,244,476,1127,1128,1129,1472,2060,2149,2253,2517,3056,3626,3627,3629,3630)			
-- Competitors: Bannatyne Fitness,David Lloyd,DW Fitness First,LA Fitness,Virgin Active,Total Fitness,Pure Gym,The Gym,DW Fitness Clubs,Anytime Fitness,Nuffield Health,Gymbox,PayAsUGym,Technogym,Thirdspace,Easy Gyms,1Rebel,JD Gyms)
CREATE CLUSTERED INDEX ix_ConsumerCombinationID on #CC(ConsumerCombinationID)


IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	FanID
INTO	#Trans
FROM	WH_Virgin.trans.consumertransaction CT
JOIN	#FB F ON F.CINID = #FB.[CT].CINID
JOIN	#CC C 	ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate > DATEADD(MONTH, -12, GETDATE())
		AND Amount > 0
GROUP BY FanID
CREATE CLUSTERED INDEX ix_CINID on #Trans(FanID)


IF OBJECT_ID('Sandbox.SamH.VM_boohoomangymgoers14022022') IS NOT NULL DROP TABLE Sandbox.SamH.VM_boohoomangymgoers14022022
SELECT	#Trans.[FanID]
INTO	Sandbox.SamH.VM_boohoomangymgoers14022022
FROM	#Trans

IF OBJECT_ID('WH_Virgin.Selections.BHO010_PreSelection') IS NOT NULL DROP TABLE WH_Virgin.Selections.BHO010_PreSelection
select [Sandbox].[SamH].[VM_boohoomangymgoers14022022].[FanID]
into Selections.BHO010_PreSelection
from Sandbox.SamH.VM_boohoomangymgoers14022022


END




