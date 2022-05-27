-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-03-06>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.LK003_PreSelection_sProcASBEGIN
IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
SELECT br.BrandID,
		br.BrandName,
		cc.ConsumerCombinationID
INTO	#CC
FROM	Warehouse.Relational.Brand br
JOIN	Warehouse.Relational.ConsumerCombination cc ON br.BrandID = cc.BrandID
WHERE	br.BrandID in (1365)
ORDER BY br.BrandName
CREATE CLUSTERED INDEX ix_ComboID ON #cc(BrandID,ConsumerCombinationID)

--IF OBJECT_ID('tempdb..#BeautyBox') IS NOT NULL DROP TABLE #BeautyBox
--SELECT	CINID,
--		TranDate,
--		MID,
--		Amount
--INTO	#BeautyBox
--FROM	Relational.ConsumerTransaction_MyRewards my
--JOIN	Relational.ConsumerCombination cc on cc.consumercombinationid = my.consumercombinationid
--WHERE	BrandID = '1365'
--AND		Amount IN ('15','14.50','13.75','13.00')
--AND		TranDate >= DATEADD(MONTH,-12,GETDATE()) 
--ORDER BY 1,2

--SELECT	Amount,
--		COUNT(1)
--FROM	#BeautyBox
--GROUP BY Amount

--SELECT *
--FROM	#BeautyBox
--ORDER BY 1,2

--SELECT	CINID,
--		TranDate,
--		MID,
--		Amount
--FROM	Relational.ConsumerTransaction_MyRewards my
--JOIN	Relational.ConsumerCombination cc on cc.consumercombinationid = my.consumercombinationid
--WHERE	BrandID = '1365'
--AND		TranDate >= DATEADD(MONTH,-12,GETDATE()) 


--IF OBJECT_ID('tempdb..#BeautyBoxPayments') IS NOT NULL DROP TABLE #BeautyBoxPayments
--SELECT	CINID,
--		COUNT(1) AS MonthlyPayments
--INTO	#BeautyBoxPayments
--FROM	#BeautyBox
--GROUP BY CINID

--IF OBJECT_ID('tempdb..#BeautyBoxCustomers') IS NOT NULL DROP TABLE #BeautyBoxCustomers
--SELECT	CINID
--INTO	#BeautyBoxCustomers
--FROM	#BeautyBoxPayments
--WHERE	MonthlyPayments >= 3


--SELECT	MID,
--		Amount
--FROM	Relational.ConsumerTransaction_MyRewards my
--JOIN	Relational.ConsumerCombination cc on cc.consumercombinationid = my.consumercombinationid
--WHERE	BrandID = '1365'
--AND		TranDate >= DATEADD(MONTH,-9,GETDATE())

----Transactions--
--SELECT	TranDate,
--		SUM(Amount) AS Spend,
--		COUNT(1) AS Transactions,
--		COUNT(DISTINCT CINID) AS Spenders

--FROM	Relational.ConsumerTransaction_MyRewards my
--JOIN	#CC cc on cc.ConsumerCombinationID = my.ConsumerCombinationID
--WHERE	TranDate >= '2019-01-01'
--AND		Amount > 0
--GROUP BY TranDate
--ORDER BY 1

IF OBJECT_ID('tempdb..#FullBase') IS NOT NULL DROP TABLE #FullBase
SELECT	CL.CINID,
		cu.FanID
INTO	#FullBase
FROM	Relational.Customer cu
JOIN	Relational.CINList cl on cu.SourceUID = cl.CIN
WHERE	cu.CurrentlyActive = 1 -- for active customers
AND		cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID)
CREATE UNIQUE CLUSTERED INDEX cx_Stuff ON #FullBase (CINID)


DECLARE @MainBrand INT = 1365
If Object_ID('tempdb..#SegmentAssignment1') IS NOT NULL DROP TABLE #SegmentAssignment1
Select cl.CINID,
		Acquire,
		Amount,
		SUM(Trans) AS Transa
INTO #SegmentAssignment1

FROM	 #FullBase cl
LEFT JOIN (SELECT	ct.CINID,
					Amount,
					COUNT(1) AS Trans,
					MAX(CASE WHEN BrandID = @MainBrand AND DATEADD(WEEK,-52,GETDATE()) <= TranDate AND TranDate <= GETDATE() THEN 1 ELSE 0 END) AS Acquire
			FROM	Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
			JOIN	#CC cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
			
			WHERE	0 < ct.Amount
			AND		TranDate >= DATEADD(WEEK,-104,GETDATE())
			AND		Amount NOT IN ('13','13.75','14.5','15')
			GROUP BY ct.CINID,Amount) b on cl.CINID = b.CINID
GROUP BY cl.CINID,
		Acquire,
		Amount

--SELECT	SUM(CASE WHEN Amount >= 50 THEN Amount ELSE 0 END) AS AboveSpend,
--		SUM(CASE WHEN Amount >= 50 THEN Transa ELSE 0 END) AS AboveTrans
--FROM	#SegmentAssignment1
--WHERE	Acquire = 0 OR Acquire IS NULL



--SELECT	Acquire,
--		COUNT(1)
--FROM	#SegmentAssignment1
--GROUP BY Acquire

IF OBJECT_ID('Sandbox.SamW.LookFantastic_Acquire_100221') IS NOT NULL DROP TABLE Sandbox.SamW.LookFantastic_Acquire_100221
SELECT	CINID
INTO	Sandbox.SamW.LookFantastic_Acquire_100221
FROM	#SegmentAssignment1
WHERE	Acquire = 0 OR Acquire IS NULL


If Object_ID('tempdb..#ATVGroup') IS NOT NULL DROP TABLE #ATVGroup
SELECT		s.CINID,
			a.ATV
INTO		#ATVGroup
FROM		#SegmentAssignment1 s
LEFT JOIN	(SELECT CINID,
					SUM(Amount) AS Spend,
					COUNT(1) AS Trans,
					SUM(Amount)/COUNT(1) AS ATV
			 FROM	Relational.ConsumerTransaction_MyRewards ct
			 JOIN	#CC cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
			 WHERE	TranDate >= DATEADD(MONTH,-12,GETDATE())
			 GROUP BY CINID) a on a.CINID = s.CINID
WHERE		Acquire = 1

--SELECT	CINID,
--		CASE WHEN 30 <= ATV AND ATV <= 40 THEN 'Group1'
--			 WHEN 41 <= ATV AND ATV <= 50 THEN 'Group2'
--			 WHEN 51 <= ATV AND ATV <= 60 THEN 'Group3'
--		ELSE 'NoGroup' END AS 'ATVGroup'
--FROM	#ATVGroup

--IF OBJECT_ID('Sandbox.SamW.LookFantastic_Group1ATV_100221') IS NOT NULL DROP TABLE Sandbox.SamW.LookFantastic_Group1ATV_100221
--SELECT	CINID
--INTO	Sandbox.SamW.LookFantastic_Group1ATV_100221
--FROM	#ATVGroup
--WHERE	30 <= ATV AND ATV <= 40
--AND		CINID NOT IN (SELECT CINID FROM Sandbox.SamW.LookFantastic_Acquire_100221)




IF OBJECT_ID('Sandbox.SamW.LookFantastic_Group2ATV_100221') IS NOT NULL DROP TABLE Sandbox.SamW.LookFantastic_Group2ATV_100221
SELECT	CINID
INTO	Sandbox.SamW.LookFantastic_Group2ATV_100221
FROM	#ATVGroup
WHERE	41 <= ATV AND ATV <= 50
AND		CINID NOT IN (SELECT CINID FROM Sandbox.SamW.LookFantastic_Acquire_100221)




--IF OBJECT_ID('Sandbox.SamW.LookFantastic_Group3ATV_100221') IS NOT NULL DROP TABLE Sandbox.SamW.LookFantastic_Group3ATV_100221
--SELECT	CINID
--INTO	Sandbox.SamW.LookFantastic_Group3ATV_100221
--FROM	#ATVGroup
--WHERE	51 <= ATV AND ATV <= 60
--AND		CINID NOT IN (SELECT CINID FROM Sandbox.SamW.LookFantastic_Acquire_100221)
If Object_ID('Warehouse.Selections.LK003_PreSelection') Is Not Null Drop Table Warehouse.Selections.LK003_PreSelectionSelect FanIDInto Warehouse.Selections.LK003_PreSelectionFROM  #FullBase fbWHERE EXISTS (	SELECT 1				FROM Sandbox.SAMW.LookFantastic_Group2ATV_100221 sb				WHERE fb.CINID = sb.CINID)END