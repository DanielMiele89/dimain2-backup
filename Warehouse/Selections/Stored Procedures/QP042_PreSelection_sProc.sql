-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2019-09-06>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
Create Procedure Selections.QP042_PreSelection_sProc
AS
BEGIN

--QPARK--361
--SECTOR ID = 4--
--DVLA--1264

--CONSUMER COMBINATIONS FOR DVLA/PETROL--
IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT ConsumerCombinationID
		,B.BrandID
		,BrandName

INTO #CC

FROM	Relational.ConsumerCombination CC

JOIN	Relational.Brand B ON B.BrandID = CC.BrandID

WHERE	B.BrandID IN (1264, 361)

OR		B.SectorID = 4

CREATE CLUSTERED INDEX ix_ComboID ON #CC(ConsumerCombinationID)


--SEGMENTATION--
IF OBJECT_ID('tempdb..#SA') IS NOT NULL DROP TABLE #SA
SELECT	CL.CINID
		,FanID
		,QParkShopper
		,DVLAShopper
		,PetrolShopper

INTO #SA

FROM	(	select CL.CINID
						,cu.FanID
				from warehouse.Relational.Customer cu
				INNER JOIN warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
				where cu.CurrentlyActive = 1
					and cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
					and cu.PostalSector in (select distinct dtm.fromsector 
						from warehouse.relational.DriveTimeMatrix as dtm with (NOLOCK)
						where dtm.tosector IN (select distinct substring([PostCode],1,charindex(' ',[PostCode],1)+1) 
															 from warehouse.relational.outlet
															 WHERE 	partnerid = 4553
															 AND City LIKE '%Liverpool%')--adjust to outlet)
															 AND dtm.DriveTimeMins <= 90)
				group by CL.CINID, cu.FanID
			) CL

LEFT JOIN	(SELECT CINID
					,MAX(CASE WHEN BrandID = 361 AND TranDate > DATEADD(MONTH, -6, GETDATE()) THEN 1 ELSE 0 END) QPARKSHOPPER
					,MAX(CASE WHEN BrandID = 1264 THEN 1 ELSE 0 END) DVLASHOPPER
					,MAX(CASE WHEN BrandID <> 361 AND BrandID <> 1264 THEN 1 ELSE 0 END) PetrolShopper

				FROM	Relational.ConsumerTransaction_MyRewards CTMR With (NoLock)

				JOIN	#CC ON #CC.ConsumerCombinationID = CTMR.ConsumerCombinationID

				WHERE	TranDate > DATEADD(YEAR, -1, GETDATE()) 
				GROUP BY CINID) A ON A.CINID = CL.CINID


CREATE CLUSTERED INDEX ix_ComboID ON #SA(CINID) 


--SELECT	QParkShopper
--		,DVLAShopper
--		,PetrolShopper
--		,COUNT(*) People

--FROM	#SA

--GROUP BY QParkShopper
--		,DVLAShopper
--		,PetrolShopper

IF OBJECT_ID('Sandbox.SamW.QPark_Liverpool_13082019') IS NOT NULL DROP TABLE Sandbox.SamW.QPark_Liverpool_13082019
SELECT CINID
		,FANID

INTO Sandbox.SamW.QPark_Liverpool_13082019

FROM #SA
WHERE	QPARKSHOPPER <> 1 
AND DVLASHOPPER = 1
OR PetrolShopper = 1

If Object_ID('Warehouse.Selections.QP042_PreSelection') Is Not Null Drop Table Warehouse.Selections.QP042_PreSelection
Select FanID
Into Warehouse.Selections.QP042_PreSelection
From Sandbox.SamW.QPark_Liverpool_13082019


END