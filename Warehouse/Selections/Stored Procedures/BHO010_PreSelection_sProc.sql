
CREATE PROCEDURE [Selections].[BHO010_PreSelection_sProc]
AS
BEGIN
	
IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID, FanID
INTO	#FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID) 
AND		Gender = 'M'
CREATE CLUSTERED INDEX ix_CINID on #FB(CINID)

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT	  CC.ConsumerCombinationID AS ConsumerCombinationID
INTO	#CC 
FROM	Relational.ConsumerCombination CC
WHERE	BrandID IN (31,113,161,244,476,1127,1128,1129,1472,2060,2149,2253,2517,3056,3626,3627,3629,3630)			
-- Competitors: Bannatyne Fitness,David Lloyd,DW Fitness First,LA Fitness,Virgin Active,Total Fitness,Pure Gym,The Gym,DW Fitness Clubs,Anytime Fitness,Nuffield Health,Gymbox,PayAsUGym,Technogym,Thirdspace,Easy Gyms,1Rebel,JD Gyms)

IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	FanID
		,COUNT(CT.CINID) AS Txn
INTO	#Trans
FROM	Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC CC ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN	#FB F ON F.CINID = CT.CINID
WHERE	TranDate > DATEADD(MONTH, -12, GETDATE())
		AND Amount > 0
GROUP BY FanID


IF OBJECT_ID('Sandbox.SamH.RBS_boohoomangymgoers14022022') IS NOT NULL DROP TABLE Sandbox.SamH.RBS_boohoomangymgoers14022022
SELECT	FanID
INTO Sandbox.SamH.RBS_boohoomangymgoers14022022
FROM  #Trans

IF OBJECT_ID('Warehouse.Selections.BHO010_PreSelection') IS NOT NULL DROP TABLE Warehouse.Selections.BHO010_PreSelection
select FanID
into Selections.BHO010_PreSelection
from Sandbox.SamH.RBS_boohoomangymgoers14022022

END

