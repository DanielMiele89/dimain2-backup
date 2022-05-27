/******************************************************************************
PROCESS NAME: Offer Calculation - Pre-Transactions - Insert Outlier Exclusions

Author	  Hayden Reid
Created	  23/09/2016
Purpose	  Inserts partners that have not been analysed into the outlier exclusion table
		  ready for querying against Scheme/Match/Consumer Trans

Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

01/01/0000 Developer Full Name
A comprehensive description of the changes. The description may use as 
many lines as needed.

******************************************************************************/
CREATE PROCEDURE [Report].[OfferReport_Insert_OutlierExclusions] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    --EXEC Staging.OfferReport_Fetch_OutlierReport

    DECLARE @CycleStart DATETIME2(7) = (SELECT [Report].[OfferReport_GetCycleDate](1))
    DECLARE @CycleEnd DATETIME2(7) = (SELECT [Report].[OfferReport_GetCycleDate](0))

	DECLARE @MonthStartDateInt INT
		,	@MonthStartDate DATETIME2(7)
		,	@MonthEndDate DATETIME2(7)
	
	EXEC @MonthStartDateInt = [Report].[MonthStartDate_Fetch]	-- If adjusting adjustments late for Monthly Reports, manually set this to the first of the relevant month
	SET @MonthStartDate = (SELECT CONVERT(DATETIME, CONVERT(CHAR(8), CAST(CONVERT(CHAR(8), @MonthStartDateInt, 112) AS INT))));
    SET @MonthEndDate = DATEADD(MS, -1, DATEADD(D, 1, CONVERT(DATETIME2, EOMONTH(@MonthStartDate))));

	--	SELECT	@CycleStart
	--		,	@CycleEnd
	--		,	@MonthStartDate
	--		,	@MonthEndDate

    -- Get Partners that are being calculated
    IF OBJECT_ID('tempdb..#PIDs') IS NOT NULL DROP TABLE #PIDs
	SELECT	DISTINCT
			pa.RetailerID
		,	pa.RetailerName
		,	pa.BrandID
		,	pa.BrandName
    INTO #PIDs
	FROM [Report].[OfferReport_AllOffers] ao
	LEFT JOIN [Derived].[Partner] pa
		ON ao.PartnerID = pa.PartnerID
    
    -- Remove any partners that are already in exclusion table and not in the checking table
    DELETE p
	FROM #PIDs p
    WHERE EXISTS (	SELECT 1
					FROM [Report].[OfferReport_OutlierExclusion] oe
					WHERE oe.RetailerID = p.RetailerID
					AND oe.EndDate IS NULL)

    -- Rank partners for looping
    IF OBJECT_ID('tempdb..#LoopDef') IS NOT NULL DROP TABLE #LoopDef
    SELECT	ROW_NUMBER() OVER (ORDER BY RetailerID) as rnum
		,	*
    INTO #LoopDef
    FROM #PIDs

    -- Loop variables to cycle through remaining partners
    DECLARE @BrandID int, @RetailerID int, @Counter int, @Max int
    SET @Counter = 1
    SET @MAX = (SELECT MAX(rnum) FROM #LoopDef)

    WHILE @Counter <= @Max
    BEGIN

		SET @BrandID = (SELECT BrandID FROM #LoopDef WHERE rnum = @Counter)
		SET @RetailerID = (SELECT RetailerID FROM #LoopDef WHERE rnum = @Counter)

		IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
		CREATE TABLE #CC (ConsumerCombinationID INT PRIMARY KEY)

		INSERT INTO #CC
		SELECT	ConsumerCombinationID
		FROM [Warehouse].[Relational].[ConsumerCombination] cc
		WHERE cc.BrandID = @BrandID

		IF @RetailerID = 4938
			BEGIN
				INSERT INTO #CC
				SELECT	ConsumerCombinationID
				FROM [Warehouse].[Relational].[ConsumerCombination] cc
				WHERE EXISTS (	SELECT 1
								FROM [SLC_Report].[dbo].[RetailOutlet] ro
								WHERE cc.MID = ro.MerchantID
								AND ro.PartnerID = @RetailerID)
			END


		IF OBJECT_ID('tempdb..#CC_DD') IS NOT NULL DROP TABLE #CC_DD
		CREATE TABLE #CC_DD (ConsumerCombinationID_DD INT PRIMARY KEY)

		INSERT INTO #CC_DD
		SELECT	ConsumerCombinationID_DD
		FROM [Warehouse].[Relational].[ConsumerCombination_DD] cc
		WHERE cc.BrandID = @BrandID

		-- Assign a percentile for each transaction
		IF OBJECT_ID('tempdb..#ptile') IS NOT NULL DROP TABLE #PTile;
		WITH
		Trans AS (	SELECT	ct.Amount
					FROM [Warehouse].[Relational].[ConsumerTransaction] ct WITH (NOLOCK)
					WHERE TranDate BETWEEN @MonthStartDate AND @MonthEndDate
					AND Amount > 0
					AND EXISTS (SELECT 1
								FROM #CC cc
								WHERE ct.ConsumerCombinationID = cc.ConsumerCombinationID)
					UNION ALL
					SELECT	ct.Amount
					FROM [Warehouse].[Relational].[ConsumerTransaction_CreditCard] ct WITH (NOLOCK)
					WHERE TranDate BETWEEN @MonthStartDate AND @MonthEndDate
					AND Amount > 0
					AND EXISTS (SELECT 1
								FROM #CC cc
								WHERE ct.ConsumerCombinationID = cc.ConsumerCombinationID)
					UNION ALL
					SELECT	ct.Amount
					FROM [Warehouse].[Relational].[ConsumerTransaction_DD] ct WITH (NOLOCK)
					WHERE TranDate BETWEEN @MonthStartDate AND @MonthEndDate
					AND Amount > 0
					AND EXISTS (SELECT 1
								FROM #CC_DD cc
								WHERE ct.ConsumerCombinationID_DD = cc.ConsumerCombinationID_DD))

		SELECT	BrandID = @BrandID
			,	RetailerID = @RetailerID
			,	Amount
			,	NTILE(100) OVER (ORDER BY Amount DESC) AS PTile
		INTO #Ptile
		FROM Trans ct

		-- Calculate the overall percentage of spend above a certain percentile
		IF OBJECT_ID('tempdb..#PTileSummary') IS NOT NULL DROP TABLE #PTileSummary
		SELECT	SUM(CASE WHEN PTILE <= 1 THEN Amount ELSE 0 END) / SUM(Amount) AS Ptile1Pct
			,	SUM(CASE WHEN PTILE <= 2 THEN Amount ELSE 0 END) / SUM(Amount) AS Ptile2Pct
			,	SUM(CASE WHEN PTILE <= 3 THEN Amount ELSE 0 END) / SUM(Amount) AS Ptile3Pct
			,	SUM(CASE WHEN PTILE <= 4 THEN Amount ELSE 0 END) / SUM(Amount) AS Ptile4Pct
			,	SUM(CASE WHEN PTILE <= 5 THEN Amount ELSE 0 END) / SUM(Amount) AS Ptile5Pct
		INTO #PTileSummary
		FROM #PTile

	   --SELECT * FROM #PTile
	   --SELECT * FROM #PTileSummary

		INSERT INTO [Report].[OfferReport_OutlierExclusion] (	BrandID
															,	UpperValue
															,	RetailerID
															,	StartDate
															,	EndDate)
		SELECT	BrandID
			,	UpperValue
			,	RetailerID
			,	@CycleStart
			,	NULL
		FROM (	MERGE [Report].[OfferReport_OutlierExclusion] oe
				USING (	SELECT	BrandID
							,	RetailerID
							,	UpperValue = MIN(Amount)
						FROM #PTile
						WHERE PTile = (	SELECT	CASE 
													WHEN 0.1 BETWEEN 0 AND ptile1pct THEN 1
													WHEN 0.1 BETWEEN ptile1pct AND ptile2pct THEN 2
													WHEN 0.1 BETWEEN ptile2pct AND ptile3pct THEN 3
													WHEN 0.1 BETWEEN ptile3pct AND ptile4pct THEN 4
													WHEN 0.1 BETWEEN ptile4pct AND ptile5pct THEN 5
													ELSE 5 
												END
										FROM #PTileSummary)
						GROUP BY	RetailerID
								,	BrandID) p
				ON (p.RetailerID = oe.RetailerID)
		  
				WHEN MATCHED AND oe.EndDate IS NULL
				THEN UPDATE
				SET oe.EndDate = DATEADD(DAY, -1, @CycleStart)
		
				WHEN NOT MATCHED
				THEN INSERT VALUES (p.BrandID, p.UpperValue, p.RetailerID, '2012-01-01', NULL)
		
				OUTPUT $action Act, p.*) x
	  
		WHERE Act = 'UPDATE'

		SET @Counter = @Counter + 1

    END

END


