-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-07-12>-- Description: < sProc to run preselection code per camapign >-- =============================================Create Procedure Selections.HIE004_PreSelection_sProcASBEGIN--SELECT TOP 10 *
--FROM Warehouse.Relational.Partner
--WHERE PartnerName LIKE '%Holiday%Inn%'

--SELECT *
--FROM Warehouse.Relational.Outlet
--WHERE PartnerID = 4728
--ORDER BY 7

--PARTNER ID 4727 HOLIDAY INN--
IF OBJECT_ID('tempdb..#HI') IS NOT NULL DROP TABLE #HI
SELECT	*

INTO #HI

FROM	Relational.Outlet

WHERE	(City LIKE '%Edinburgh%'
OR CITY LIKE '%Glasgow%'
OR CITY LIKE '%Liverpool%'
OR CITY LIKE '%Manchester%'
OR CITY LIKE '%Birmingham%'
OR CITY LIKE '%London%'
OR CITY LIKE '%York%'
OR CITY LIKE '%Leeds%'
OR CITY LIKE '%Oxford%'
OR CITY LIKE '%Cardiff%'
OR CITY LIKE '%Norwich%'
OR CITY LIKE 'Chester'
OR CITY LIKE '%Belfast%'
OR Address2 LIKE '%Heathrow%Airport%Hayes')

AND		PartnerID = 4728

CREATE CLUSTERED INDEX ix_ComboID ON #HI(PostalSector)

--SELECT *
--FROM #HI


--FULL BASE--
IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID
		,FANID

INTO #FB

FROM	Relational.Customer C 

JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID

WHERE	C.CurrentlyActive = 1

AND		C.SourceUID NOT IN (SELECT DISTINCT SourceUID FROM Staging.Customer_DuplicateSourceUID)

CREATE CLUSTERED INDEX ix_ComboID ON #FB(CINID)


--FORMATTED POSTCODES OF GIVEN AREAS--
DECLARE @MINDRIVETIME INT = 10
IF OBJECT_ID('tempdb..#FORMATTEDDTM') IS NOT NULL DROP TABLE #FORMATTEDDTM
SELECT	DISTINCT ToSector

INTO #FORMATTEDDTM

FROM	Relational.DriveTimeMatrix DTM

JOIN	#HI ON #HI.PostalSector = DTM.FromSector

WHERE	DriveTimeMins < = @MINDRIVETIME


SELECT COUNT(Distinct ToSector), COUNT(ToSector)
FROM #FORMATTEDDTM

--CONSUMER COMBINATION FOR THE POSTCODES --
IF OBJECT_ID('tempdb..#CCP') IS NOT NULL DROP TABLE #CCP
SELECT	ConsumerCombinationID
		,LEFT(PostCode,LEN(PostCode) - 2) ComboPostCode

INTO #CCP

FROM	AWSFile.ComboPostCode CPC

JOIN	#FORMATTEDDTM FDTM ON REPLACE(FDTM.ToSector,' ','') = LEFT(PostCode,LEN(PostCode) - 2)

CREATE CLUSTERED INDEX ix_ComboID ON #CCP(ConsumerCombinationID)

SELECT COUNT(Distinct ConsumerCombinationID), COUNT(ConsumerCombinationID)
FROM #CCP

--PEOPLE WHO HAVE SHOPPED AT THE CONSUMER COMBINATION IN THE PAST 12 MONTHS--
DECLARE @STARTDATE DATE = DATEADD(WEEK, -56, GETDATE())
DECLARE @ENDDATE DATE = GETDATE()
IF OBJECT_ID('tempdb..#SHOPPERS') IS NOT NULL DROP TABLE #SHOPPERS
SELECT	DISTINCT #FB.CINID
		
INTO #SHOPPERS

FROM	#FB

JOIN	Relational.ConsumerTransaction_MyRewards CTMR ON CTMR.CINID = #FB.CINID

JOIN	#CCP ON #CCP.ConsumerCombinationID = CTMR.ConsumerCombinationID

WHERE	CTMR.Amount > 0 

AND		CTMR.TranDate >= @STARTDATE

AND		CTMR.TranDate < @ENDDATE


--SEGMENT ASSIGNEMT -- 
IF OBJECT_ID('tempdb..#SA') IS NOT NULL DROP TABLE #SA
SELECT	#FB.CINID
		,#FB.FanID

INTO #SA

FROM	#FB

JOIN	#SHOPPERS S ON S.CINID = #FB.CINID

SELECT COUNT(DISTINCT CINID), COUNT(CINID)
FROM #SA


--SANDBOX--
IF OBJECT_ID('Sandbox.SamW.Holiday_Inn_Express_City_Centres_13062019') IS NOT NULL DROP TABLE Sandbox.SamW.Holiday_Inn_Express_City_Centres_13062019
SELECT	#SA.FanID
		,#SA.CINID

INTO Sandbox.SamW.Holiday_Inn_Express_City_Centres_13062019

FROM #SA

CREATE CLUSTERED INDEX ix_ComboID ON Sandbox.SamW.Holiday_Inn_Express_City_Centres_13062019(CINID)


If Object_ID('Warehouse.Selections.HIE004_PreSelection') Is Not Null Drop Table Warehouse.Selections.HIE004_PreSelectionSelect FanIDInto Warehouse.Selections.HIE004_PreSelectionFrom Sandbox.SamW.Holiday_Inn_Express_City_Centres_13062019END