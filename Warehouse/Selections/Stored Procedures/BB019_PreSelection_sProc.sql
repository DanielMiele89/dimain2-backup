-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-11-15>-- Description: < sProc to run preselection code per camapign >-- =============================================Create Procedure Selections.BB019_PreSelection_sProcASBEGIN--FULL BASE--
IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FANID

INTO #FB
FROM	Relational.Customer C

JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID

WHERE	C.CurrentlyActive = 1 

AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)

CREATE CLUSTERED INDEX ix_ComboID ON #FB(CINID) 


--OUTLET ID = 119531
--POSTAL SECTORS FOR KENSINGTON STORE WITHIN WALKING DISTANCE--
IF OBJECT_ID('tempdb..#PostCodes') IS NOT NULL DROP TABLE #PostCodes
SELECT DISTINCT REPLACE(ToSector,' ','') PostCode
INTO #PostCodes
FROM	Relational.DriveTimeMatrix DTM
JOIN	(SELECT PostalSector
		FROM Relational.Outlet
		WHERE OutletID = 119531) O ON O.PostalSector = DTM.FromSector

AND DTM.DriveTimeMins <= 5



--CONSUMERCOMBINATIONS WITHIN 1 MINUTE DRIVE TIME OF KENSINGTON STORE
IF OBJECT_ID('tempdb..#LOCALPOSTCODES') IS NOT NULL DROP TABLE #LOCALPOSTCODES
SELECT	cc.ConsumerCombinationID
		,CC.BrandID
		,BrandName
		,PC.PostCode

INTO #LOCALPOSTCODES

FROM	AWSFile.ComboPostCode CPC

JOIN	Relational.ConsumerCombination CC ON CPC.ConsumerCombinationID = CC.ConsumerCombinationID

JOIN	Relational.Brand B ON CC.BrandID = B.BrandID

JOIN	#PostCodes PC ON PC.PostCode = LEFT(CPC.PostCode,LEN(CPC.PostCode) - 2)

--THOSE WHO LIVE WITHIN 20 MINUTES OF KENSINGTON STORE
IF OBJECT_ID('tempdb..#LOCALCUSTOMERS') IS NOT NULL DROP TABLE #LOCALCUSTOMERS
SELECT	DISTINCT CINID
		,FANID

INTO #LOCALCUSTOMERS

FROM	Relational.Customer C

JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID

JOIN	Relational.DriveTimeMatrix DTM ON C.PostalSector = DTM.FromSector

WHERE	DTM.ToSector IN (SELECT PostalSector
		FROM Relational.Outlet
		WHERE OutletID = 119531)

AND		DTM.DriveTimeMins < = 20


--SEGMENT ASSIGNMENT--
IF OBJECT_ID('tempdb..#SALocalSpend') IS NOT NULL DROP TABLE #SALocalSpend
SELECT	#FB.CINID
		,#FB.FanID
		,CASE WHEN LP.CONSUMERCOMBINATIONID IS NOT NULL THEN 1 ELSE 0 END LocalSpender
		,COUNT(1) LocalTransactions

INTO #SALocalSpend

FROM	#FB

JOIN	Relational.ConsumerTransaction_MyRewards CTMR ON CTMR.CINID = #FB.CINID

JOIN #LOCALPOSTCODES LP ON LP.ConsumerCombinationID = CTMR.ConsumerCombinationID

WHERE TRANDATE >= DATEADD(YEAR,-1, GETDATE())

GROUP BY #FB.CINID
		,#FB.FanID
		,CASE WHEN LP.CONSUMERCOMBINATIONID IS NOT NULL THEN 1 ELSE 0 END



IF OBJECT_ID('tempdb..#SALocalCustomers') IS NOT NULL DROP TABLE #SALocalCustomers
SELECT	#FB.CINID
		,#FB.FanID
		,CASE WHEN LC.CINID IS NOT NULL THEN 1 ELSE 0 END LocalCustomer

INTO #SALocalCustomers

FROM	#FB

JOIN	Relational.ConsumerTransaction_MyRewards CTMR ON CTMR.CINID = #FB.CINID

JOIN #LOCALCUSTOMERS LC ON LC.CINID = #FB.CINID

WHERE TRANDATE >= DATEADD(YEAR,-1, GETDATE())

GROUP BY #FB.CINID
		,#FB.FanID
		,CASE WHEN LC.CINID IS NOT NULL THEN 1 ELSE 0 END


IF OBJECT_ID('tempdb..#SA') IS NOT NULL DROP TABLE #SA
SELECT	#FB.CINID
		,#FB.FanID
		,LocalSpender
		,LocalTransactions
		,LocalCustomer

INTO #SA

FROM	#FB

LEFT JOIN	#SALocalSpend T ON T.CINID = #FB.CINID

LEFT JOIN	#SALocalCustomers S ON S.CINID = #FB.CINID

IF OBJECT_ID('Sandbox.SamW.ByronKensington101019') IS NOT NULL DROP TABLE Sandbox.SamW.ByronKensington101019
SELECT CINID,FanID
INTO Sandbox.SamW.ByronKensington101019
FROM #SA
WHERE CINID NOT IN (SELECT CINID FROM Sandbox.SamW.ByronMVC101019 UNION SELECT CINID FROM Sandbox.Samw.ByronCompSteal101019)
AND (LocalCustomer IS NOT NULL 
OR LocalTransactions IS NOT NULL 
OR LocalSpender IS NOT NULL )If Object_ID('Warehouse.Selections.BB019_PreSelection') Is Not Null Drop Table Warehouse.Selections.BB019_PreSelectionSelect FanIDInto Warehouse.Selections.BB019_PreSelectionFrom Sandbox.SamW.ByronKensington101019END