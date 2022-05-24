-- =============================================-- Author:  <Rory Francis>-- Create date: <2020-03-06>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[BB021_PreSelection_sProc]ASBEGIN--SELECT *

--FROM Warehouse.Relational.Brand

--WHERE BrandName LIKE '%Byron%'

--SELECT *
--FROM Relational.Partner --4668
--WHERE BrandID = 1434

--SELECT *
--FROM Relational.Outlet O
--WHERE PartnerID = 4668

--Consumer Combination for main brand postcodes--
IF OBJECT_ID ('tempdb..#CTH') IS NOT NULL DROP TABLE #CTH
SELECT ConsumerCombinationID,
		Postcode
INTO	#CTH
FROM	AWSFile.ComboPostCode

WHERE	PostCode IN ('W127GF')

--SELECT DISTINCT POSTCODE FROM #CTH
--ORDER BY 1


--Formatting main brand postcodes--
IF OBJECT_ID ('tempdb..#BAPostcode') IS NOT NULL DROP TABLE #BAPostcode
SELECT LEFT(Postcode,LEN(Postcode) - 2) AS BA_Postcode
INTO	#BAPostcode
FROM	#CTH


--Join to drive time and state dt minutes
DECLARE @MinThreshold INT = 5
IF OBJECT_ID ('tempdb..#LocalPostcodes') IS NOT NULL DROP TABLE #LocalPostcodes
SELECT dtm.ToSector
INTO #LocalPostcodes
FROM Warehouse.Relational.DriveTimeMatrix dtm

WHERE EXISTS
	( SELECT 1
	 FROM #BAPostcode s
	 WHERE	REPLACE(FromSector,' ','') = s.BA_Postcode
	)
AND DriveTimeMins <= @MinThreshold


--Consumer Combination from AWSFile Postcodes--
IF OBJECT_ID('tempdb..#ComboPostCode') IS NOT NULL DROP TABLE #ComboPostCode
SELECT	cpc.ConsumerCombinationID,
		b.BrandID,
		BrandName,
		LEFT(Postcode,LEN(Postcode) - 2) AS PostalSector

INTO	#ComboPostCode

FROM	AWSFile.ComboPostCode cpc
JOIN	Relational.ConsumerCombination cc on cc.ConsumerCombinationID = cpc.ConsumerCombinationID
JOIN	Relational.Brand b on b.BrandID = cc.BrandID
WHERE	cc.BrandID <> 944
CREATE CLUSTERED INDEX cix_PostalSector ON #ComboPostCode (PostalSector)


--Consumer Combination for local shopper postcodes--
IF OBJECT_ID('tempdb..#LocalStores') IS NOT NULL DROP TABLE #LocalStores
SELECT	ConsumerCombinationID,
		BrandID,
		BrandName

INTO	#LocalStores

FROM	#ComboPostCode cp
JOIN	#LocalPostcodes lp ON cp.PostalSector = REPLACE(lp.ToSector,' ','')

CREATE CLUSTERED INDEX cix_ConsumerCombinationID ON #LocalStores (ConsumerCombinationID)


--Tran Dates for Local Shoppers--
DECLARE @StartDate DATE = DATEADD(MONTH,-12,GETDATE())
DECLARE @EndDate DATE = GETDATE()
IF OBJECT_ID('tempdb..#DateSplit') IS NOT NULL DROP TABLE #DateSplit
SELECT CINID,
		DATEPART(WEEK, TranDate) AS WeekNo,
		DATEPART(WEEKDAY, TranDate) AS WeekDayNo,
		COUNT(1) as Tran_Count

INTO #DateSplit

FROM	Warehouse.Relational.ConsumerTransaction_MyRewards ct WITH (NOLOCK)
JOIN	#LocalStores l ON ct.ConsumerCombinationID = l.ConsumerCombinationID

WHERE	0 < ct.Amount
AND		ct.TranDate BETWEEN @StartDate AND @EndDate
AND		IsOnline = 0

GROUP BY CINID,
		 DATEPART(WEEK, TranDate),
		 DATEPART(WEEKDAY, TranDate)


--How many tran dates for each person--
IF OBJECT_ID('tempdb..#DateSplitGroup') IS NOT NULL DROP TABLE #DateSplitGroup
SELECT CINID,
		COUNT(1) AS Tran_Days,
		SUM(Tran_Count) AS Total_Transactions

INTO	#DateSplitGroup

FROM	#DateSplit

GROUP BY CINID

--Segment Assignment--
If Object_ID('tempdb..#SegmentAssignment') IS NOT NULL DROP TABLE #SegmentAssignment
Select cl.CINID,			-- keep CINID and FANID
		cl.fanid,
		MAX(CASE WHEN c.CINID IS NOT NULL THEN 1 ELSE 0 END) AS 'LocalTrans'

INTO #SegmentAssignment

FROM		(SELECT CINID,
					 FanID
	
			 FROM Relational.Customer cu
			 JOIN Relational.CINList cl on cu.SourceUID = cl.CIN

			 WHERE cu.CurrentlyActive = 1
			 AND cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )

			 GROUP BY CINID, FanID) cl

LEFT JOIN	 (SELECT CL.CINID,
					 cu.FanID
	
			 FROM warehouse.Relational.Customer cu
			 JOIN warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN

			 WHERE cu.CurrentlyActive = 1
			 AND cu.sourceuid NOT IN (SELECT DISTINCT sourceuid FROM warehouse.Staging.Customer_DuplicateSourceUID )
				) dt on dt.CINID = cl.CINID
																			
LEFT JOIN	 (SELECT CINID

			 FROM #DateSplitGroup

			 WHERE Tran_Days >= 5
			 ) c on cl.CINID = c.CINID

GROUP BY cl.CINID,
		 cl.fanid


SELECT TOP 10 *
FROM #SegmentAssignment
WHERE LocalTrans = 1

--SELECT DriveTime,
--		LocalTrans,
--		COUNT(1) AS Counts

--FROM #SegmentAssignment

--GROUP BY DriveTime,LocalTrans


--IF OBJECT_ID('Sandbox.SamW.Byron_190220') IS NOT NULL DROP TABLE Sandbox.SamW.Byron_190220
--SELECT CINID,
--		FanID

--INTO Sandbox.SamW.Byron_190220

--FROM #SegmentAssignment

--WHERE LocalTrans = 1

IF OBJECT_ID('Sandbox.SamW.Byron_DTLT_190220') IS NOT NULL DROP TABLE Sandbox.SamW.Byron_DTLT_190220
SELECT CINID,
		FanID

INTO Sandbox.SamW.Byron_DTLT_190220

FROM #SegmentAssignment

WHERE LocalTrans = 1
If Object_ID('Warehouse.Selections.BB021_PreSelection') Is Not Null Drop Table Warehouse.Selections.BB021_PreSelectionSelect FanIDInto Warehouse.Selections.BB021_PreSelectionFROM  SANDBOX.SAMW.BYRON_DTLT_190220END