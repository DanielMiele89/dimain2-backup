
CREATE PROCEDURE [Staging].[MID_Checking_ReportSP]
			(@TableName NVARCHAR(200))

AS

BEGIN
/*
Title: MID Checking Report
Author: Suraj Chahal
Creation Date: 23 Apr 2014
Purpose: Load MIDs into a table then exec this SP with the Table Name and this will search for the MIDs in our transactional warehouse
	The Output can be added to a spreadsheet and sent to person requesting the data.
*/


--DECLARE @TableName NVARCHAR(200)
--SET @TableName = 'Sandbox.Suraj.ArgosMIDs'

DECLARE @Qry NVARCHAR(MAX)
SET @Qry =
'
IF OBJECT_ID (''tempdb..##CleanMIDs'') IS NOT NULL DROP TABLE ##CleanMIDs
SELECT	CASE 
		WHEN LEFT(MID,10) = ''0000000000'' THEN RIGHT(MID,LEN(MID)-10)
		WHEN LEFT(MID,9) = ''000000000'' THEN RIGHT(MID,LEN(MID)-9)
		WHEN LEFT(MID,8) = ''00000000'' THEN RIGHT(MID,LEN(MID)-8)
		WHEN LEFT(MID,7) = ''0000000'' THEN RIGHT(MID,LEN(MID)-7)
		WHEN LEFT(MID,6) = ''000000'' THEN RIGHT(MID,LEN(MID)-6)
		WHEN LEFT(MID,5) = ''00000'' THEN RIGHT(MID,LEN(MID)-5)
		WHEN LEFT(MID,4) = ''0000'' THEN RIGHT(MID,LEN(MID)-4)
		WHEN LEFT(MID,3) = ''000'' THEN RIGHT(MID,LEN(MID)-3)
		WHEN LEFT(MID,2) = ''00'' THEN RIGHT(MID,LEN(MID)-2)
		WHEN LEFT(MID,1) = ''0'' THEN RIGHT(MID,LEN(MID)-1)
		ELSE MID
	END as MID
INTO ##CleanMIDs
FROM '+ @TableName
--SELECT @Qry
EXEC sp_sqlexec @Qry


IF OBJECT_ID ('tempdb..#MIDsInCC') IS NOT NULL DROP TABLE #MIDsInCC
SELECT      cc.*,
      m.MCCDesc,
      b.BrandName,
      cm.MID as CleanMID
INTO #MIDsInCC
FROM Warehouse.Relational.ConsumerCombination cc
INNER JOIN ##CleanMIDs cm
      ON RIGHT(cc.MID,LEN(cm.MID)) = cm.MID
INNER JOIN Warehouse.Relational.MCCList m
      ON cc.MCCID = m.MCCID
Inner JOIN Warehouse.Relational.Brand b
      ON cc.BrandID = b.BrandID
Where LocationCountry = 'GB'
--(880 row(s) affected)

-------------------------------------------------------------------------
Delete FROM #MIDsInCC
Where Cast(left(MID,Len(MID)-Len(CleanMID)) as int) <> 0
-------------------------------------------------------------------------

--SELECT * FROM #MIDsInCC


IF OBJECT_ID ('tempdb..#FirstLastTrans') IS NOT NULL DROP TABLE #FirstLastTrans
SELECT	cc.MID as MerchantID,
	isOnline, 
	MIN(ct.TranDate) as FirstTransaction,
	MAX(ct.TranDate) as LastTransaction
INTO #FirstLastTrans
FROM #MIDsInCC cc
INNER JOIN Warehouse.Relational.ConsumerTransaction ct WITH (NOLOCK)
	ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
GROUP BY cc.MID, isOnline



IF OBJECT_ID ('tempdb..#SpendLastMonth') IS NOT NULL DROP TABLE #SpendLastMonth
SELECT	cc.MID as MerchantID,
	COUNT(1) as TransactionsInMonth,
	SUM(ct.Amount) as SpendLastMonth
INTO #SpendLastMonth
FROM #MIDsInCC cc
INNER JOIN Warehouse.Relational.ConsumerTransaction ct WITH (NOLOCK)
	ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
WHERE TranDate BETWEEN CAST(DATEADD(MM,-1,GETDATE())AS DATE) AND CAST(GETDATE() AS DATE)
GROUP BY cc.MID



IF OBJECT_ID ('tempdb..#SpendLastYear') IS NOT NULL DROP TABLE #SpendLastYear
SELECT	cc.MID as MerchantID,
	COUNT(1) as TransactionsInYear,
	SUM(ct.Amount) as SpendLastYear
INTO #SpendLastYear
FROM #MIDsInCC cc
INNER JOIN Warehouse.Relational.ConsumerTransaction ct WITH (NOLOCK)
	ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
WHERE TranDate BETWEEN CAST(DATEADD(YY,-1,GETDATE())AS DATE) AND CAST(GETDATE() AS DATE)
GROUP BY cc.MID


IF OBJECT_ID ('tempdb..#MIDsWithTrans') IS NOT NULL DROP TABLE #MIDsWithTrans
SELECT	DISTINCT 
	MID,
	Narrative,
	MCCDesc,
	CASE 
		WHEN IsOnline = 1 THEN 'Online'
		ELSE 'Offline'
	END as isOnline,
	f.FirstTransaction,
	f.LastTransaction,
	sy.SpendLastYear,
	sm.SpendLastMonth,
	sy.TransactionsInYear,
	sm.TransactionsInMonth
INTO #MIDsWithTrans
FROM #MIDsInCC cc
LEFT OUTER JOIN #FirstLastTrans f
	ON cc.MID = f.MerchantID
LEFT OUTER JOIN #SpendLastYear sy
	ON cc.MID = sy.MerchantID
LEFT OUTER JOIN #SpendLastMonth sm
	ON cc.MID = sm.MerchantID
--(18 row(s) affected)


SELECT	c.MID,
	ISNULL(m.Narrative,'MID Not in Transactional Data') as Narrative,
	MCCDesc,
	isOnline,
	FirstTransaction,
	LastTransaction,
	SpendLastYear,
	SpendLastMonth,
	TransactionsInYear,
	TransactionsInMonth
FROM	(
	SELECT * 
	FROM ##CleanMIDs
	) c
LEFT OUTER JOIN #MIDsWithTrans m
	ON c.MID = RIGHT(m.MID,LEN(c.MID))
ORDER BY m.MID DESC



--SELECT * FROM #MIDsWithTrans
--SELECT * FROM #CleanMIDs
--SELECT * FROM #MIDsInCC
--SELECT * FROM #FirstLastTrans
--SELECT * FROM #SpendLastMonth
--SELECT * FROM #SpendLastYear


--SELECT TOP 10 * FROM Warehouse.Relational.ConsumerTransaction ct WITH (NOLOCK)
--SELECT TOP 10 * FROM Warehouse.Relational.ConsumerCombination 
--SELECT TOP 10 * FROM Warehouse.[Relational].[MCCList]

END