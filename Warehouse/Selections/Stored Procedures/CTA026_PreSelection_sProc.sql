
CREATE PROCEDURE [Selections].[CTA026_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID, C.FanID
INTO	#FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
CREATE CLUSTERED INDEX ix_FanID on #FB(FanID)


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC			
SELECT	CC.BrandID, ConsumerCombinationID, B.BrandName			
INTO	#CC
FROM	Relational.ConsumerCombination CC
JOIN	Relational.Brand B ON B.BrandID = CC.BrandID
WHERE	CC.BrandID IN  (485,275,61,379,425,278,914,354,409)		-- Brands: Waitrose 485, Marks & Spencer Simply Food 275, Boots 61, Sainsburys 379, Tesco 425, Mcdonalds 278, Greggs 914, Pret 354, Subway 409
CREATE CLUSTERED INDEX ix_CCID on #CC(ConsumerCombinationID)


SET DATEFIRST 1;		-- MONDAY

IF OBJECT_ID('tempdb..#Txn') IS NOT NULL DROP TABLE #Txn		-- Grocery Lunchtime Spender= spent £3-£8, 3 times per week (excluding sat & sun) with one of the above brands in one week 
SELECT   CT.CINID												-- (can spend at multiple brands during the week period) in the last 3 months
		,DATEADD(DAY, 1 - DATEPART(WEEKDAY, CAST(TranDate AS DATE)), CAST(TranDate AS DATE)) as Week_Commencing
		,COUNT(1) AS Transactions
		, fb.fanid
		,SUM(Amount) AS Spend
INTO	#Txn
FROM	Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC CC	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN	#FB FB	ON CT.CINID = FB.CINID
WHERE	TranDate >= DATEADD(MONTH,-3,GETDATE())
		AND Amount BETWEEN 3 AND 8
		AND DATENAME(WEEKDAY,TranDate) NOT IN ('Saturday','Sunday')
GROUP BY CT.CINID, fb.fanid
		,DATEADD(DAY, 1 - DATEPART(WEEKDAY, CAST(trandate AS DATE)), CAST(trandate AS DATE))
HAVING	COUNT(1) >= 3
CREATE CLUSTERED INDEX ix_CINID on #Txn(CINID)


IF OBJECT_ID('tempdb..#CC2') IS NOT NULL DROP TABLE #CC2		
SELECT	CC.BrandID, ConsumerCombinationID			
INTO	#CC2
FROM	Relational.ConsumerCombination CC
WHERE	CC.BrandID IN  (2009,2518,1122)		-- Brands: Deliveroo 2009 & Uber Eats 2518, JUST EAT 1122
CREATE CLUSTERED INDEX ix_CCID on #CC2(ConsumerCombinationID)

SET DATEFIRST 1;		-- MONDAY

IF OBJECT_ID('tempdb..#Txn2') IS NOT NULL DROP TABLE #Txn2		-- Deliveroo & Uber Eats- add them in and check the maximum spend bracket might need to be adjusted to £12 or £15
SELECT   CT.CINID												
		,DATEADD(DAY, 1 - DATEPART(WEEKDAY, CAST(TranDate AS DATE)), CAST(TranDate AS DATE)) as Week_Commencing
		,COUNT(1) AS Transactions
		, fb.fanid
		,SUM(Amount) AS Spend
INTO	#Txn2
FROM	Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC2 CC	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN	#FB FB	ON CT.CINID = FB.CINID
WHERE	TranDate >= DATEADD(MONTH,-3,GETDATE())
		AND Amount BETWEEN 7 AND 15
		AND DATENAME(WEEKDAY,TranDate) NOT IN ('Saturday','Sunday')
GROUP BY CT.CINID, fb.fanid
		,DATEADD(DAY, 1 - DATEPART(WEEKDAY, CAST(trandate AS DATE)), CAST(trandate AS DATE))
CREATE CLUSTERED INDEX ix_CINID on #Txn2(CINID)	

-- FC2 txn limit 1+
IF OBJECT_ID('Sandbox.rukank.Costa_LunchtimeSpender_FC1_and_2_txn1_28012022') IS NOT NULL DROP TABLE Sandbox.rukank.Costa_LunchtimeSpender_FC1_and_2_txn1_28012022			-- 567,871
SELECT	CINID
INTO	Sandbox.rukank.Costa_LunchtimeSpender_FC1_and_2_txn1_28012022
FROM	(SELECT CINID  FROM	#Txn
		  UNION
		 SELECT CINID  FROM	#Txn2
		  ) F
GROUP BY CINID

CREATE CLUSTERED INDEX CIX_CINID ON Sandbox.rukank.Costa_LunchtimeSpender_FC1_and_2_txn1_28012022 (CINID)

IF OBJECT_ID('Warehouse.Selections.CTA026_PreSelection') IS NOT NULL DROP TABLE Warehouse.Selections.CTA026_PreSelection			-- 567,871
select FanID
INTO Warehouse.Selections.CTA026_PreSelection	
from #FB fb
WHERE EXISTS (	SELECT 1
				FROM Sandbox.rukank.Costa_LunchtimeSpender_FC1_and_2_txn1_28012022 st
				WHERE fb.CINID = st.CINID)

END