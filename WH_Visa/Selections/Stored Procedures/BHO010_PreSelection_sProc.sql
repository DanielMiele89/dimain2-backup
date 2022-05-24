
CREATE PROCEDURE [Selections].[BHO010_PreSelection_sProc]
AS
BEGIN

	
IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FanID
INTO	#FB
FROM	WH_Visa.Derived.Customer  C
JOIN	WH_Visa.Derived.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Derived.Customer_DuplicateSourceUID) 
AND		Gender = 'M'
CREATE CLUSTERED INDEX ix_CINID on #FB(CINID)


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
		,BrandID
INTO	#CC
FROM	WH_Visa.Trans.ConsumerCombination  CC
WHERE	BrandID IN (31,113,161,244,476,1127,1128,1129,1472,2060,2149,2253,2517,3056,3626,3627,3629,3630)			
-- Competitors: Bannatyne Fitness,David Lloyd,DW Fitness First,LA Fitness,Virgin Active,Total Fitness,Pure Gym,The Gym,DW Fitness Clubs,Anytime Fitness,Nuffield Health,Gymbox,PayAsUGym,Technogym,Thirdspace,Easy Gyms,1Rebel,JD Gyms)


IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	FanID
		,COUNT(CT.CINID) AS Txn
INTO	#Trans
FROM	#FB F
JOIN	WH_Visa.Trans.Consumertransaction CT ON F.CINID = CT.CINID
JOIN	#CC C ON C.ConsumerCombinationID = CT.ConsumerCombinationID
WHERE	TranDate > DATEADD(MONTH, -12, GETDATE())
		AND Amount > 0
GROUP BY FANID


IF OBJECT_ID('Sandbox.SamH.BC_boohoomangymgoers14022022') IS NOT NULL DROP TABLE Sandbox.SamH.BC_boohoomangymgoers14022022
SELECT	FanID
INTO	Sandbox.SamH.BC_boohoomangymgoers14022022
FROM	#Trans

IF OBJECT_ID('WH_Visa.Selections.BHO010_PreSelection') IS NOT NULL DROP TABLE WH_Visa.Selections.BHO010_PreSelection
select FanID
into Selections.BHO010_PreSelection
from Sandbox.SamH.BC_boohoomangymgoers14022022


END

