
CREATE PROCEDURE [Selections].[CTA028_PreSelection_sProc]
AS
BEGIN

--Acquire and Lapsed:

--SELECT * FROM Relational.Brand WHERE BrandName LIKE '%just%'

IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT	CINID, FanID
INTO	#FB
FROM	Relational.Customer C
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
WHERE	C.CurrentlyActive = 1
AND		SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
CREATE CLUSTERED INDEX ix_FanID on #FB(CINID)


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
		,SUM(Amount) AS Spend
INTO	#Txn
FROM	Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC CC	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN	#FB FB	ON CT.CINID = FB.CINID
WHERE	TranDate >= DATEADD(MONTH,-3,GETDATE())
		AND Amount BETWEEN 3 AND 8
		AND DATENAME(WEEKDAY,TranDate) NOT IN ('Saturday','Sunday')
GROUP BY CT.CINID
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
		,SUM(Amount) AS Spend
INTO	#Txn2
FROM	Relational.ConsumerTransaction_MyRewards CT
JOIN	#CC2 CC	ON CT.ConsumerCombinationID = CC.ConsumerCombinationID
JOIN	#FB FB	ON CT.CINID = FB.CINID
WHERE	TranDate >= DATEADD(MONTH,-3,GETDATE())
		AND Amount BETWEEN 7 AND 15
		AND DATENAME(WEEKDAY,TranDate) NOT IN ('Saturday','Sunday')
GROUP BY CT.CINID
		,DATEADD(DAY, 1 - DATEPART(WEEKDAY, CAST(trandate AS DATE)), CAST(trandate AS DATE))
CREATE CLUSTERED INDEX ix_CINID on #Txn2(CINID)	


-- Grocery spenders txn limit 3+ and Delivery spenders txn limit 1+
IF OBJECT_ID('Sandbox.GunayS.Costa_LunchtimeSpender_AL_07042022') IS NOT NULL DROP TABLE Sandbox.GunayS.Costa_LunchtimeSpender_AL_07042022			
SELECT	F.CINID
INTO	Sandbox.GunayS.Costa_LunchtimeSpender_AL_07042022
FROM	(SELECT CINID  FROM	#Txn
		  UNION
		 SELECT CINID  FROM	#Txn2
		  ) F
GROUP BY F.CINID







----	Low SoW
---- This tool is to produce the outputs used for the standard Forecasting tool - 
-----------------------------------------------------------------------------------------------------------------------------------------
---- To find brand ID, input brand name -- 
-----------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------
---- input custom Acquire and Lapsed lengths --
--	DECLARE @AcquireLength INT			= 12
--	DECLARE	@LapsedLength INT			= 6
--	DECLARE @Monthstocheck INT			= 32				-- motnhs to go back for checking trends
--	DECLARE	@BrandID INT				= 101
--	DECLARE	@BrandName varchar(500)		= (SELECT BrandName FROM Relational.Brand WHERE BrandID = @BrandID)
--	DECLARE @SpendStretch INT			= 0 -- 100			-- If Needed, otherwise default to zero
--	DECLARE	@NurseryOfferJump INT		= 1					-- Month Diff btw transaction dates for a customer to join Nursery offer
--	DECLARE @SELECTION_table TABLE (CINID INT NOT NULL)
--	INSERT INTO @SELECTION_table 
--		   SELECT CINID
--		   FROM Sandbox.GunayS.Costa_LunchtimeSpender_LowSoW_07042022

-----------------------------------------------------------------------------------------------------------------------------------------
---- Populate Full Active Base of RBS Customers
-----------------------------------------------------------------------------------------------------------------------------------------
--		DECLARE @TimeStart DATETIME = GETDATE(), @time DATETIME, @RowsAffected INT
--		EXEC Prototype.oo_TimerMessage_V2 'STARTED', @RowsAffected, @time OUTPUT

--		IF OBJECT_ID('tempdb..#FB') IS NOT NULL DROP TABLE #FB
--		SELECT	C.FanID		,CINID
--		INTO	#FB
--		FROM	Relational.Customer C
--		JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID
--		WHERE	C.CurrentlyActive = 1
--				AND SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
--		SET		@RowsAffected = @@ROWCOUNT -- (2775046 rows affected) / 00:00:06
--		CREATE CLUSTERED INDEX ix_FanID on #FB(FANID)
--		EXEC	Prototype.oo_TimerMessage_V2 '#FB', @RowsAffected, @time OUTPUT

-----------------------------------------------------------------------------------------------------------------------------------------
---- Cycle Dates
-----------------------------------------------------------------------------------------------------------------------------------------
---- Populate #Cycles table with cycle dates up to the input year @Year
--		IF OBJECT_ID('tempdb..#Cycles') IS NOT NULL DROP TABLE #Cycles;
--		SELECT	StartDate CycleStartDate
--				,EndDate CycleEndDate
--				,ROW_NUMBER() OVER (ORDER BY StartDate ASC) CycleNumber
--		INTO	#Cycles
--		FROM	Relational.ROC_CycleDates 
--		WHERE	StartDate >= DATEADD(MONTH,-@AcquireLength - @Acquirelength -@Monthstocheck, GETDATE())
--		CREATE CLUSTERED INDEX CIX_CYCLES_CYCLESTARTDATE ON #Cycles (CycleStartDate)


-----------------------------------------------------------------------------------------------------------------------------------------
---- Consumer Combinations for chosen Brand
-----------------------------------------------------------------------------------------------------------------------------------------
--		IF OBJECT_ID('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs
--		SELECT	ConsumerCombinationID
--		INTO	#CCIDs
--		FROM	Relational.ConsumerCombination cc WITH (NOLOCK)
--		WHERE	BrandID = @BrandID
--		GROUP BY ConsumerCombinationID
--		CREATE CLUSTERED INDEX CIX_CCID_CCID ON #CCIDs (ConsumerCombinationID)

-----------------------------------------------------------------------------------------------------------------------------------------
---- Transaction Tables for Forecast
-----------------------------------------------------------------------------------------------------------------------------------------
--		IF OBJECT_ID('tempdb..#CT') IS NOT NULL DROP TABLE #CT
--		SELECT ct.CINID
--				 , ct.TranDate
--				 , Amount
--				 , CycleStartDate
--				 , Classification AS AwarenessLevel
--				 , MAX(CASE WHEN S.CINID IS NOT NULL THEN 1 ELSE 0 END) SELECTION											-- Use both if not using bespoke selection -- Filter by 1 for bespoke
--				 , ROW_NUMBER ( )   OVER ( PARTITION BY CT.CINID, CycleStartDate ORDER BY TranDate ASC) TransactionNumber	-- Later only the first transaction is being selected
--		INTO	#CT
--		FROM	#CCIDs CCs
--		JOIN	Relational.ConsumerTransaction_MyRewards ct		ON CCs.ConsumerCombinationID = ct.ConsumerCombinationID
--		JOIN	#FB F 	ON F.CINID = CT.CINID
--		JOIN	#Cycles C	ON TranDate BETWEEN C.CycleStartDate AND C.CycleEndDate
--		LEFT JOIN InsightArchive.EngagementScore E ON E.FanID = F.FanID
--		LEFT JOIN (SELECT CINID from @SELECTION_table) S	ON F.CINID = S.CINID						-- SANDBOX Fore bespoke targetting --
--		WHERE	TranDate >= DATEADD(MONTH,-@AcquireLength -@acquirelength -@monthstocheck , GETDATE())
--				AND Amount > 0																			-- To ignore Returns
--		GROUP BY CT.CINID
--				,TranDate
--				, Amount
--				, CycleStartDate 
--				, Classification
--		CREATE CLUSTERED INDEX ix_CINID ON #CT(CINID)

-----------------------------------------------------------------------------------------------------------------------------------------
---- Finding Previous & Next Transactions To Segment the customers
-----------------------------------------------------------------------------------------------------------------------------------------
--		IF OBJECT_ID('tempdb..#CT_Lag') IS NOT NULL DROP TABLE #CT_Lag
--		SELECT	*
--				, LAG (TranDate) OVER (PARTITION BY CINID ORDER BY TranDate) As PreviousTranDate
--				, DATEDIFF(month, LAG (CycleStartDate) OVER (PARTITION BY CINID ORDER BY CycleStartDate), CycleStartDate) AS MonthsSinceLastTran
--				, DATEDIFF(month, CycleStartDate, LEAD (CycleStartDate) OVER (PARTITION BY CINID ORDER BY CycleStartDate)) AS MonthsSinceNextTran
--				, LEAD(Amount) OVER (PARTITION BY CINID ORDER BY CycleStartDate) AS NextTranAmount
--		INTO	#CT_Lag
--		FROM	#CT
--		CREATE CLUSTERED INDEX ix_CINID ON #CT_LAG(CINID)

-----------------------------------------------------------------------------------------------------------------------------------------
---- Segmenting the customers
-----------------------------------------------------------------------------------------------------------------------------------------
--		IF OBJECT_ID('tempdb..#CustomerSegment') IS NOT NULL DROP TABLE #CustomerSegment
--		SELECT *
--				, CASE
--				   WHEN MonthsSinceLastTran IS NULL OR MonthsSinceLastTran >= @AcquireLength THEN 'Acquire'
--					WHEN MonthsSinceLastTran >= @LapsedLength THEN 'Lapsed'
--					ELSE 'Shopper'
--				END AS CustomerSegmentOnTranDate
--				, CASE
--				   WHEN MonthsSinceNextTran IS NULL OR MonthsSinceNextTran > @NurseryOfferJump THEN 0
--					WHEN MonthsSinceNextTran = 0 THEN 1					-- check this to make sure same cycle txn counts
--					ELSE 1
--				END AS NurseryOffer
--		INTO	#CustomerSegment
--		FROM	#CT_Lag
--		CREATE CLUSTERED INDEX ix_CINID ON #CustomerSegment(CINID)

-----------------------------------------------------------------------------------------------------------------------------------------
---- Grouping the customers for single transaction line per customer per cycle
-----------------------------------------------------------------------------------------------------------------------------------------
--		IF OBJECT_ID('tempdb..#SegmentonCycle') IS NOT NULL DROP TABLE #SegmentonCycle
--		SELECT	 CINID	
--				,CycleStartDate										
--				,SUM(Amount) AS Amount						
--				,SUM(NextTranAmount) AS NextTranAmount
--				,COUNT(CINID) AS TranVolume
--		INTO	#SegmentonCycle
--		FROM	#CustomerSegment
--		GROUP BY CINID	
--				,CycleStartDate								
--		CREATE CLUSTERED INDEX ix_CINID ON #SegmentonCycle(CINID)

-----------------------------------------------------------------------------------------------------------------------------------------
---- Output
-----------------------------------------------------------------------------------------------------------------------------------------
--		IF OBJECT_ID('tempdb..#Output') IS NOT NULL DROP TABLE #Output
--		SELECT
--			 @BrandName BrandName
--			,S.CycleStartDate
--			,C.CustomerSegmentOnTranDate AS Segment
--			,SELECTION
--			,NurseryOffer
--			,@NurseryOfferJump AS NextTran_WithinMonths
----			,CASE WHEN Amount >= @SpendStretch THEN 1 ELSE 0 END SpendStretch			-- If no spend stretch, use both --
--			,AwarenessLevel
--			,SUM(S.Amount) Spend
--			,SUM(TranVolume) Transactions
--			,COUNT(DISTINCT S.CINID) Customers
--			,SUM(CASE WHEN C.NurseryOffer = 1 THEN S.NextTranAmount ELSE 0 END)	AS NextTran_Amount
--		INTO #Output
--		FROM #SegmentonCycle S
--		LEFT JOIN  #CustomerSegment C	
--				ON C.CINID = S.CINID	
--				AND C.CycleStartDate = S.CycleStartDate		
--				AND C.TransactionNumber = 1			
--		WHERE	S.CycleStartDate >= DATEADD(MONTH,-@acquirelength -@monthstocheck ,GETDATE())		
--		GROUP BY C.CustomerSegmentOnTranDate
--				,S.CycleStartDate
--				,NurseryOffer
--				,SELECTION
----				,CASE WHEN Amount >= @SpendStretch THEN 1 ELSE 0 END
--				,AwarenessLevel


--	--SELECT MAX(tranDate) AS 'Last Txn Date'
--	--FROM Relational.ConsumerTransaction_MyRewards

-- -- --FORECASTING OUTPUT
--	--SELECT 'Forecasting Output'
--	--SELECT *
--	--FROM #Output
--	--ORDER BY CycleStartDate DESC

--	--SELECT   @AcquireLength as 'Acquired Length'	,@LapsedLength as 'Lapsed Length'


--	IF OBJECT_ID('tempdb..#TotalCardHolders') IS NOT NULL DROP TABLE #TotalCardHolders
--	SELECT '1. Total Cardholders' AS BespokeCardholder, COUNT(DISTINCT S.CINID) AS 'Cardholders'							-- use this figure when using a bespoke selection to change cardholder table
--	INTO #TotalCardHolders
--	FROM @SELECTION_table S													

--	IF OBJECT_ID('tempdb..#LSCardHolders') IS NOT NULL DROP TABLE #LSCardHolders
--	SELECT	'2. Lapsed & Shopper Cardholders' AS BespokeCardholder, COUNT(DISTINCT S.CINID) AS 'Carholders'
--	INTO #LSCardHolders
--	FROM @SELECTION_table S											
--	JOIN Relational.ConsumerTransaction_MyRewards CT ON S.CINID = CT.CINID
--	JOIN #CCIDs cc	ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
--	WHERE TranDate >= DATEADD(MONTH,-@AcquireLength,GETDATE())

--	IF OBJECT_ID('tempdb..#SCardHolders') IS NOT NULL DROP TABLE #SCardHolders
--	SELECT	'3. Shopper Cardholders' AS BespokeCardholder, COUNT(DISTINCT S.CINID)	AS 'Cardholders'
--	INTO #SCardHolders
--	FROM @SELECTION_table S											
--	JOIN Relational.ConsumerTransaction_MyRewards CT ON S.CINID = CT.CINID
--	JOIN #CCIDs cc	ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
--	WHERE TranDate >= DATEADD(MONTH,-@LapsedLength,GETDATE())

	--SELECT *
	--FROM (SELECT *  FROM	#TotalCardHolders
	--	  UNION
	--	  SELECT *  FROM	#LSCardHolders
	--	  UNION
	--	  SELECT *  FROM	#SCardHolders
	--	  ) A

	IF OBJECT_ID('[Warehouse].[Selections].[CTA028_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[CTA028_PreSelection]
	SELECT FanID
	INTO [Warehouse].[Selections].[CTA028_PreSelection]
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.GunayS.Costa_LunchtimeSpender_AL_07042022  st
					WHERE fb.CINID = st.CINID)
	AND EXISTS (	SELECT 1
					FROM Segmentation.Roc_Shopper_Segment_Members sg
					WHERE fb.FanID = sg.FanID
					AND sg.PartnerID = 4781
					AND sg.EndDate IS NULL
					AND sg.ShopperSegmentTypeID IN (7, 8))
					
	INSERT INTO [Warehouse].[Selections].[CTA028_PreSelection]
	SELECT FanID
	FROM #FB fb
	WHERE EXISTS (	SELECT 1
					FROM Sandbox.GunayS.Costa_LunchtimeSpender_LowSoW_07042022  st
					WHERE fb.CINID = st.CINID)
	AND EXISTS (	SELECT 1
					FROM Segmentation.Roc_Shopper_Segment_Members sg
					WHERE fb.FanID = sg.FanID
					AND sg.PartnerID = 4781
					AND sg.EndDate IS NULL
					AND sg.ShopperSegmentTypeID IN (9))

END