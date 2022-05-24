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
CREATE PROCEDURE [Staging].[OfferReport_Insert_OutlierExclusions_20211114] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    --EXEC Staging.OfferReport_Fetch_OutlierReport

    DECLARE @CycleStart DATE = (SELECT MI.GetCycleDate(1))
    DECLARE @CycleEnd DATE = (SELECT MI.GetCycleDate(0))


    DECLARE @ReportMonthStart DATE, @ReportMonthEnd DATE

    SET @ReportMonthStart = DATEADD(DAY, 1, EOMONTH(GETDATE(), -2))
    SET @ReportMonthEnd = EOMONTH(@ReportMonthStart)

    -- Get Partners that are being calculated
    IF OBJECT_ID('tempdb..#PIDs') IS NOT NULL DROP TABLE #PIDs
    SELECT DISTINCT PartnerID, BrandID
    INTO #PIDs
    FROM (
	   SELECT DISTINCT
		  a.PartnerID
		  , p.BrandID
	   FROM Warehouse.Staging.OfferReport_AllOffers a
	   JOIN Warehouse.Relational.Partner p on p.PartnerID = a.PartnerID

	   UNION ALL

	   SELECT DISTINCT 
		  ISNULL(p.PartnerID, a.PartnerID) PartnerID
		  , ISNULL(b.BrandID, a.BrandID) BrandID
	   FROM Warehouse.Staging.OfferReport_AllOffers a
	   LEFT JOIN nfi.Relational.Partner p on p.PartnerID = a.PartnerID
	   LEFT JOIN Warehouse.Relational.Brand b 
		  on b.BrandName = p.PartnerName
		  OR CASE p.PartnerName
			 WHEN 'Apollo - Quidco' THEN 'Apollo'
			 WHEN 'Barrhead Travel (Lloyds Cardnet)' THEN 'Barrhead Travel'
			 WHEN 'Cherry Lane Garden Centre' THEN 'Cherry Lane Garden Centres'
			 WHEN 'Caffè Nero' THEN 'Caffe Nero'
			 WHEN 'Hughes' THEN 'Hughes Direct'
			 WHEN 'PRC Direct' THEN 'PRC Direct'
			 WHEN 'Caffe Nero (e)' THEN 'Caffe Nero'
			 WHEN 'Sixt UK' THEN 'Sixt Car Rental'
			 WHEN 'Bank Fashion' THEN 'Bank'
			 WHEN 'Charles Tyrwhitt - Quidco' THEN 'Charles Tyrwhitt'
			 WHEN 'Daniel & Lade' THEN 'Daniel and Lade'
			 WHEN 'Joy' THEN 'Joy Stores'
			 WHEN 'Direct Golf UK' THEN 'Direct Golf'
			 WHEN 'Ellis Brigham Mountain Sports' THEN 'Ellis Brigham'
			 WHEN 'TM Lewin' THEN 'T M Lewin'
			 WHEN 'JoJo Maman Bebe Ltd' THEN 'Jojo Maman Bebe'
			 WHEN 'Rojo' THEN 'Rojo Shoes'
		  END = b.BrandName

	   UNION ALL

	   SELECT DISTINCT 
		  ISNULL(p.PartnerID, a.PartnerID) PartnerID
		  , ISNULL(b.BrandID, a.BrandID) BrandID
	   FROM Warehouse.Staging.OfferReport_AllOffers a
	   LEFT JOIN [WH_Virgin].[Derived].[Partner] p on p.PartnerID = a.PartnerID
	   LEFT JOIN Warehouse.Relational.Brand b 
		  on b.BrandName = p.PartnerName
		  OR CASE p.PartnerName
			 WHEN 'Apollo - Quidco' THEN 'Apollo'
			 WHEN 'Barrhead Travel (Lloyds Cardnet)' THEN 'Barrhead Travel'
			 WHEN 'Cherry Lane Garden Centre' THEN 'Cherry Lane Garden Centres'
			 WHEN 'Caffè Nero' THEN 'Caffe Nero'
			 WHEN 'Hughes' THEN 'Hughes Direct'
			 WHEN 'PRC Direct' THEN 'PRC Direct'
			 WHEN 'Caffe Nero (e)' THEN 'Caffe Nero'
			 WHEN 'Sixt UK' THEN 'Sixt Car Rental'
			 WHEN 'Bank Fashion' THEN 'Bank'
			 WHEN 'Charles Tyrwhitt - Quidco' THEN 'Charles Tyrwhitt'
			 WHEN 'Daniel & Lade' THEN 'Daniel and Lade'
			 WHEN 'Joy' THEN 'Joy Stores'
			 WHEN 'Direct Golf UK' THEN 'Direct Golf'
			 WHEN 'Ellis Brigham Mountain Sports' THEN 'Ellis Brigham'
			 WHEN 'TM Lewin' THEN 'T M Lewin'
			 WHEN 'JoJo Maman Bebe Ltd' THEN 'Jojo Maman Bebe'
			 WHEN 'Rojo' THEN 'Rojo Shoes'
		  END = b.BrandName
    ) x
    
    -- Remove any partners that are already in exclusion table and not in the checking table
    DELETE p FROM #PIDs p
    WHERE EXISTS (
	   SELECT 1 FROM Warehouse.Staging.OfferReport_OutlierExclusion oe
	   WHERE oe.PartnerID = p.PartnerID
		  and oe.EndDate IS NULL
    )
	   --AND NOT EXISTS (
		  --SELECT 1 FROM Warehouse.Staging.OfferReport_OutlierExclusion_Checks oc
		  --WHERE oc.PartnerID = p.PartnerID
	   --)

    -- Rank partners for looping
    IF OBJECT_ID('tempdb..#LoopDef') IS NOT NULL DROP TABLE #LoopDef
    SELECT
	   ROW_NUMBER() OVER (ORDER BY PartnerID) as rnum
	   , *
    INTO #LoopDef
    FROM #PIDs

    -- Loop variables to cycle through remaining partners
    DECLARE @BrandID int, @PartnerID int, @Counter int, @Max int
    SET @Counter = 1
    SET @MAX = (SELECT MAX(rnum) FROM #LoopDef)

    WHILE @Counter <= @Max
    BEGIN

	   SET @BrandID = (SELECT BrandID FROM #LoopDef WHERE rnum = @Counter)
	   SET @PartnerID = (SELECT PartnerID FROM #LoopDef WHERE rnum = @Counter)

	   -- Assign a percentile for each transaction
	   IF OBJECT_ID('tempdb..#ptile') IS NOT NULL DROP TABLE #PTile
	   SELECT
		  @BrandID as BrandID
		  , @PartnerID as PartnerID
		  , Amount
		  , NTILE(100) OVER (ORDER BY Amount DESC) as PTile
	   INTO #Ptile
	   FROM Warehouse.Relational.ConsumerTransaction ct with (nolock)
	   JOIN Warehouse.Relational.ConsumerCombination cc
		  ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
		  AND cc.BrandID = @BrandID
	   WHERE Trandate Between @ReportMonthStart AND @ReportMonthEnd
		  AND Amount > 0

	   -- Calculate the overall percentage of spend above a certain percentile
	   IF OBJECT_ID('tempdb..#PTileSummary') IS NOT NULL DROP TABLE #PTileSummary
	   SELECT		
		  SUM(CASE WHEN PTILE <= 1 THEN Amount ELSE 0 END)/Sum(Amount) AS Ptile1Pct
		  , SUM(CASE WHEN PTILE <= 2 THEN Amount ELSE 0 END)/Sum(Amount) AS Ptile2Pct
		  , SUM(CASE WHEN PTILE <= 3 THEN Amount ELSE 0 END)/Sum(Amount) AS Ptile3Pct
		  , SUM(CASE WHEN PTILE <= 4 THEN Amount ELSE 0 END)/Sum(Amount) AS Ptile4Pct
		  , SUM(CASE WHEN PTILE <= 5 THEN Amount ELSE 0 END)/Sum(Amount) AS Ptile5Pct
	   INTO #PTileSummary
	   FROM #PTile

	   --SELECT * FROM #PTile
	   --SELECT * FROM #PTileSummary

	   INSERT INTO Warehouse.Staging.OfferReport_OutlierExclusion (BrandID, UpperValue, PartnerID, StartDate, EndDate)
	   SELECT BrandID, UpperValue, PartnerID, @CycleStart, NULL
	   FROM (
		  MERGE Warehouse.Staging.OfferReport_OutlierExclusion oe
		  USING (
			 SELECT BrandID
				, Min(Amount) as UpperValue
				, PartnerID
			 FROM #PTile
			 WHERE PTile = 
				(
				    SELECT 
					   CASE 
						  WHEN 0.1 BETWEEN 0 AND ptile1pct THEN 1
						  WHEN 0.1 BETWEEN ptile1pct AND ptile2pct THEN 2
						  WHEN 0.1 BETWEEN ptile2pct AND ptile3pct THEN 3
						  WHEN 0.1 BETWEEN ptile3pct AND ptile4pct THEN 4
						  WHEN 0.1 BETWEEN ptile4pct AND ptile5pct THEN 5
						  ELSE 5 
					   END
				    FROM #PTileSummary
				)
			 GROUP BY PartnerID, BrandID
		  ) p
		  ON (p.PartnerID = oe.PartnerID)
		  
		  WHEN MATCHED
			 AND oe.EndDate IS NULL
		  THEN
			 UPDATE SET oe.EndDate = DATEADD(DAY, -1, @CycleStart)
		 WHEN NOT MATCHED
		 THEN
			 INSERT VALUES (p.BrandID, p.UpperValue, p.PartnerID, '2012-01-01', NULL)
		 OUTPUT $action Act, p.*
	   ) x
	   WHERE Act = 'UPDATE'

	   SET @Counter = @Counter + 1

    END

END