-- =============================================
-- Author:		Dorota
-- Create date:	15/05/2015
-- =============================================

CREATE PROCEDURE [MI].[CampaignResults_InternalFinalWave_Store_Incomplete] (@ClientServicesRef VARCHAR(25), @StartDate DATE, -- unhide this row to modify SP
@ControlGroup VARCHAR(100)=NULL, @CustomerUniverse VARCHAR(100)=NULL, @AggregationLevel VARCHAR(100)=NULL) AS -- unhide this row to modify SP

--DECLARE @ClientServicesRef VARCHAR(25); SET  @ClientServicesRef='AG015'; DECLARE @StartDate DATE; SET  @StartDate='2015-04-02'; -- unhide this row to run code once
--DECLARE @ControlGroup VARCHAR(100); SET @ControlGroup=NULL; DECLARE @CustomerUniverse VARCHAR(100); SET  @CustomerUniverse=NULL; -- unhide this row to run code once
--DECLARE @AggregationLevel VARCHAR(100); SET @AggregationLevel=NULL;  -- unhide this row to run code once

BEGIN 

-- Log when Store Procedure started running in CamapainResults_Log
INSERT INTO Warehouse.MI.Campaign_Log
(StoreProcedureName,  
Parameter_ClientServicesRef, Parameter_StartDate, 
RunByUser , RunStartTime)
SELECT 'CampaignResults_InternalFinalWave_Store_Incomplete', 
@ClientServicesRef, @StartDate, 
SYSTEM_USER, GETDATE()

-- Store RowID for curently running Store Procedure
DECLARE @MY_ID AS INT;
SET @MY_ID= (SELECT SCOPE_IDENTITY());

-- Check if Results are already stored in working tables
IF (SELECT COUNT(*) FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate)>0
	 OR (SELECT COUNT(*) FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate)>0

BEGIN 

    DECLARE @SDate date = (SELECT StartDate FROM Warehouse.MI.CampaignReportLog_Incomplete WHERE ClientservicesRef = @ClientServicesRef and CalcStartDate = @StartDate)
    
    -- Decide what Parameters to Use
    IF @ControlGroup IS NULL 
    BEGIN
	   --IF 'In programme' control exists use this one, otherwise, use 'Out of programme minus CBP Halo'
	   SET @ControlGroup=(SELECT MIN(w.ControlGroup) FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete w 
	   WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate)
    END

    -- Default Customer Universe is 'FULL'
    IF @CustomerUniverse IS NULL SET @CustomerUniverse='FULL'

    IF @AggregationLevel IS NULL 
    BEGIN
	   -- For In programme default agregation is on Total Level
	   IF @ControlGroup like '%In programme%' SET @AggregationLevel='Total'
	   
	   -- For Out of programme choose the lowest aggregation level (Bespoke Cell is prioritized over Segment/Supersegment over Total)
	   IF @ControlGroup like '%Out of programme%'
	   BEGIN	  
		  SET @AggregationLevel=(SELECT MIN(w.Level) FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete w 
		  WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
		  AND ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse)
	   END
    END

    -- Check if Results exist for selected @ControlGroup, @CustomerUniverse, @AggregationLevel parameters
    IF (SELECT COUNT(*) FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
	   AND ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level=@AggregationLevel)>0
    OR (SELECT COUNT(*) FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
	   AND ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level=@AggregationLevel)>0
    
    -- If everything ok, populates ResultsFinal Table
    BEGIN 

		 -- Populate CampaignInternalResultsFinalWave (delete old entries first)
		DELETE FROM Warehouse.MI.CampaignInternalResultsFinalWave_Incomplete
		WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

		INSERT INTO Warehouse.MI.CampaignInternalResultsFinalWave_Incomplete
		(ClientServicesRef,StartDate,ControlGroup,
		CustomerUniverse,AggregationLevel,
		ControlGroupSize,Cardholders,Sales,Transactions,Spenders,
		IncrementalSales,IncrementalMargin,
		IncrementalTransactions,IncrementalSpenders,
		PooledStdDevSPC,DegreesOfFreedomSPC,
		PooledStdDevRR,DegreesOfFreedomRR,
		PooledStdDevSPS,DegreesOfFreedomSPS,
		QualyfingSales, 
		Cashback,QualyfingCashback,
		Commission,CampaignCost,
		RewardOverride, IncrementalOverride)
		SELECT DISTINCT s.ClientServicesRef, s.StartDate, 
		@ControlGroup,@CustomerUniverse, @AggregationLevel,
		COALESCE(m.ControlGroupSize,0), s.Cardholders, s.Sales, s.Transactions, s.Spenders,	 
		Stratification.least(COALESCE(m.IncrementalSales,0),s.Sales),Stratification.least(COALESCE(m.IncrementalSales,0),s.Sales)*p.Margin,
		Stratification.least(COALESCE(m.IncrementalTransactions,0),s.Transactions),Stratification.least(COALESCE(m.IncrementalSpenders,0),s.Spenders),
		mstd.PooledStdDevSPC,mstd.DegreesOfFreedomSPC,
		mstd.PooledStdDevRR,mstd.DegreesOfFreedomRR,
		mstd.PooledStdDevSPS,mstd.DegreesOfFreedomSPS,
		COALESCE(q.QualyfingSales,s.Sales),
		s.Cashback,COALESCE(q.QualyfingCashback,s.Cashback),
		s.Commission,m.CampaignCost,
		s.RewardOverride, m.IncrementalOverride	
		FROM (SELECT ClientServicesRef,StartDate, SUM(Cardholders) Cardholders, SUM(Sales) Sales, SUM(Transactions) Transactions, SUM(Spenders) Spenders,
			 SUM(Cashback) Cashback, SUM(Commission) Commission, 
			 SUM(RewardOverride) RewardOverride
			 FROM (SELECT * FROM Warehouse.MI.CampaignInternalResults_PureSales_Incomplete UNION SELECT * FROM Warehouse.MI.CampaignExternalResults_PureSales_Incomplete) a
			 WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level=@AggregationLevel
			 AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Main Results (Qualifying MIDs or Channels Only)'
			 GROUP BY ClientServicesRef,StartDate) s
		LEFT JOIN (SELECT ClientServicesRef,StartDate, AVG(Margin) Margin, AVG(r.Override_Pct_of_CBP) OverridePct
				 FROM Warehouse.MI.CampaignDetailsWave_PartnerLookup w
				 INNER JOIN Warehouse.Relational.Master_Retailer_Table r ON r.PartnerID=w.PartnerID
				 GROUP BY ClientServicesRef,StartDate) p
		ON p.ClientServicesRef=SUBSTRING(s.ClientServicesRef, 0, ISNULL(NULLIF(charindex('Bespoke', s.ClientServicesRef, 0), 0), 99)) AND p.StartDate=@SDate     
		LEFT JOIN (SELECT ClientServicesRef,StartDate, SUM(Cardholders_C) ControlGroupSize, SUM(IncrementalSales) IncrementalSales, 
				SUM(IncrementalTransactions) IncrementalTransactions, SUM(IncrementalSpenders) IncrementalSpenders,
				SUM(ExtraCommissionGenerated) CampaignCost,SUM(ExtraOverrideGenerated) IncrementalOverride -- Extra on the top of base offer
				FROM (SELECT * FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete UNION SELECT * FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete) a
				WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level=@AggregationLevel
				AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Main Results (Qualifying MIDs or Channels Only)'
				GROUP BY ClientServicesRef,StartDate) m
		ON m.ClientServicesRef=s.ClientServicesRef AND m.StartDate=s.StartDate
		LEFT JOIN (SELECT ClientServicesRef,StartDate, 
				AVG(SPC_PooledStdDev) PooledStdDevSPC, AVG(SPC_DegreesOfFreedom) DegreesOfFreedomSPC,
				AVG(RR_PooledStdDev) PooledStdDevRR, AVG(RR_DegreesOfFreedom) DegreesOfFreedomRR, 
				AVG(SPS_PooledStdDev) PooledStdDevSPS, AVG(SPS_DegreesOfFreedom) DegreesOfFreedomSPS 
				FROM (SELECT * FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete UNION SELECT * FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete) a
				WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level='Total'
				AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Main Results (Qualifying MIDs or Channels Only)'
				GROUP BY ClientServicesRef,StartDate) mstd
		ON mstd.ClientServicesRef=s.ClientServicesRef AND mstd.StartDate=s.StartDate      
		LEFT JOIN (SELECT ClientServicesRef,StartDate, SUM(Sales_M) QualyfingSales, SUM(IncrementalSales) IncrementalQualyfingSales, 
				SUM(Cashback_M) QualyfingCashback
				FROM (SELECT * FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete UNION SELECT * FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete) a
				WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level=@AggregationLevel
				AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Above Spend Threshold'
				GROUP BY ClientServicesRef,StartDate) q
		ON q.ClientServicesRef=s.ClientServicesRef AND q.StartDate=s.StartDate
		WHERE s.Cardholders>0
    
			 -- Uplif calculations
			 UPDATE Warehouse.MI.CampaignInternalResultsFinalWave_Incomplete
			 SET SalesUplift=CASE WHEN IncrementalSales<Sales THEN 1.0*IncrementalSales/(Sales-IncrementalSales) ELSE IncrementalSales END
			   ,RRUplift=CASE WHEN IncrementalSpenders<Spenders THEN 1.0*IncrementalSpenders/(Sales-IncrementalSpenders) ELSE IncrementalSpenders END
			   ,ATVUplift=CASE WHEN IncrementalTransactions<Transactions AND IncrementalSales<Sales AND Transactions>0 THEN (1.0*Sales/Transactions)/(1.0*(Sales-IncrementalSales)/(Transactions-IncrementalTransactions))-1.0 ELSE 0 END
			   ,ATFUplift=CASE WHEN IncrementalSpenders<Spenders AND IncrementalTransactions<Transactions AND Spenders>0 THEN (1.0*Transactions/Spenders)/(1.0*(Transactions-IncrementalTransactions)/(Spenders-IncrementalSpenders))-1.0 ELSE 0 END
			   ,SPS_Diff=CASE WHEN IncrementalSpenders<Spenders AND IncrementalSales<Sales AND Spenders>0 THEN (1.0*Sales/Spenders)-(1.0*(Sales-IncrementalSales)/(Spenders-IncrementalSpenders)) ELSE 0 END
			 WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

			 UPDATE Warehouse.MI.CampaignInternalResultsFinalWave_Incomplete
			 SET MainDriver=CASE WHEN SalesUplift<=0 THEN 'N/A'
							 WHEN RRUplift>=ATVUplift AND RRUplift>=ATFUplift THEN 'RR'
							 WHEN ATVUplift>=ATFUplift THEN 'ATV' ELSE 'ATF' END
			 WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

			 UPDATE Warehouse.MI.CampaignInternalResultsFinalWave_Incomplete SET
			 TScoreSPC=CASE WHEN PooledStdDevSPC>0 THEN ABS(1.0*IncrementalSales/Cardholders)/PooledStdDevSPC ELSE 0 END,
			 TScoreRR=CASE WHEN PooledStdDevRR>0 THEN ABS(1.0*IncrementalSpenders/Cardholders)/PooledStdDevRR ELSE 0 END,
			 TScoreSPS=CASE WHEN PooledStdDevSPS>0 THEN ABS(1.0*SPS_Diff)/PooledStdDevSPS ELSE 0 END
			 WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
    
			-- Significance calculations
			 UPDATE Warehouse.MI.CampaignInternalResultsFinalWave_Incomplete SET
			 PValueSPC=CASE WHEN TScoreSPC>=Probability_01 THEN 0.01 
						  WHEN TScoreSPC>=Probability_02 THEN 0.02
						  WHEN TScoreSPC>=Probability_05 THEN 0.05
						  WHEN TScoreSPC>=Probability_10 THEN 0.10
						  WHEN TScoreSPC>=Probability_20 THEN 0.20
						  WHEN TScoreSPC>=Probability_30 THEN 0.30
						  WHEN TScoreSPC>=Probability_40 THEN 0.40
						  WHEN TScoreSPC>=Probability_50 THEN 0.50
						  ELSE 1 END,
			 SignificantUpliftSPC=CASE WHEN TScoreSPC>=Probability_05 THEN 'High'
						  WHEN  TScoreSPC>=Probability_20 THEN 'Moderate'
						  ELSE 'No' END
			 FROM Warehouse.MI.CampaignInternalResultsFinalWave_Incomplete w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomSPC
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomSPC) and t.Tailes=2
			 WHERE w.ClientServicesRef=@ClientServicesRef AND w.StartDate=@StartDate
    
			 UPDATE Warehouse.MI.CampaignInternalResultsFinalWave_Incomplete SET
			 PValueRR=CASE WHEN TScoreRR>=Probability_01 THEN 0.01 
						  WHEN TScoreRR>=Probability_02 THEN 0.02
						  WHEN TScoreRR>=Probability_05 THEN 0.05
						  WHEN TScoreRR>=Probability_10 THEN 0.10
						  WHEN TScoreRR>=Probability_20 THEN 0.20
						  WHEN TScoreRR>=Probability_30 THEN 0.30
						  WHEN TScoreRR>=Probability_40 THEN 0.40
						  WHEN TScoreRR>=Probability_50 THEN 0.50
						  ELSE 1 END,
			 SignificantUpliftRR=CASE WHEN TScoreRR>=Probability_05 THEN 'High'
						  WHEN  TScoreRR>=Probability_20 THEN 'Moderate'
						  ELSE 'No' END
			 FROM Warehouse.MI.CampaignInternalResultsFinalWave_Incomplete w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomRR
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomRR) and t.Tailes=2
			 WHERE w.ClientServicesRef=@ClientServicesRef AND w.StartDate=@StartDate

			 UPDATE Warehouse.MI.CampaignInternalResultsFinalWave_Incomplete SET
			 PValueSPS=CASE WHEN TScoreSPS>=Probability_01 THEN 0.01 
						  WHEN TScoreSPS>=Probability_02 THEN 0.02
						  WHEN TScoreSPS>=Probability_05 THEN 0.05
						  WHEN TScoreSPS>=Probability_10 THEN 0.10
						  WHEN TScoreSPS>=Probability_20 THEN 0.20
						  WHEN TScoreSPS>=Probability_30 THEN 0.30
						  WHEN TScoreSPS>=Probability_40 THEN 0.40
						  WHEN TScoreSPS>=Probability_50 THEN 0.50
						  ELSE 1 END,
			 SignificantUpliftSPS=CASE WHEN TScoreSPS>=Probability_05 THEN 'High'
						  WHEN  TScoreSPS>=Probability_20 THEN 'Moderate'
						  ELSE 'No' END
			 FROM Warehouse.MI.CampaignInternalResultsFinalWave_Incomplete w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomSPS
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomSPS) and t.Tailes=2
			 WHERE w.ClientServicesRef=@ClientServicesRef AND w.StartDate=@StartDate

 		-- Populate CampaignInternalResultsFinalWave_BespokeCell (delete old entries first)   
    		DELETE FROM Warehouse.MI.CampaignInternalResultsFinalWave_BespokeCell_Incomplete
		WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

		INSERT INTO Warehouse.MI.CampaignInternalResultsFinalWave_BespokeCell_Incomplete
		(ClientServicesRef,StartDate, Cell, ControlGroup,
		CustomerUniverse,Level,
		ControlGroupSize,Cardholders,Sales,Transactions,Spenders,
		IncrementalSales,IncrementalMargin,
		IncrementalTransactions,IncrementalSpenders,
		PooledStdDevSPC,DegreesOfFreedomSPC,
		PooledStdDevRR,DegreesOfFreedomRR,
		PooledStdDevSPS,DegreesOfFreedomSPS,
		QualyfingSales, 
		Cashback,QualyfingCashback,
		Commission,CampaignCost,
		RewardOverride, IncrementalOverride)
		SELECT DISTINCT s.ClientServicesRef, s.StartDate, s.Cell, 
		@ControlGroup,@CustomerUniverse, 'Bespoke Total',
		COALESCE(m.ControlGroupSize,0), s.Cardholders, s.Sales, s.Transactions, s.Spenders,	 
		Stratification.least(COALESCE(m.IncrementalSales,0),s.Sales),Stratification.least(COALESCE(m.IncrementalSales,0),s.Sales)*p.Margin,
		Stratification.least(COALESCE(m.IncrementalTransactions,0),s.Transactions),Stratification.least(COALESCE(m.IncrementalSpenders,0),s.Spenders),
		mstd.PooledStdDevSPC,mstd.DegreesOfFreedomSPC,
		mstd.PooledStdDevRR,mstd.DegreesOfFreedomRR,
		mstd.PooledStdDevSPS,mstd.DegreesOfFreedomSPS,
		COALESCE(q.QualyfingSales,s.Sales),
		s.Cashback,COALESCE(q.QualyfingCashback,s.Cashback),
		s.Commission,m.CampaignCost,
		s.RewardOverride, m.IncrementalOverride	
		FROM (SELECT ClientServicesRef,StartDate,Cell, SUM(Cardholders) Cardholders, SUM(Sales) Sales, SUM(Transactions) Transactions, SUM(Spenders) Spenders,
			 SUM(Cashback) Cashback, SUM(Commission) Commission, 
			 SUM(RewardOverride) RewardOverride
			 FROM (SELECT * FROM Warehouse.MI.CampaignInternalResults_PureSales_Incomplete UNION SELECT * FROM Warehouse.MI.CampaignExternalResults_PureSales_Incomplete) a
			 WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level='Bespoke Total'
			 AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Main Results (Qualifying MIDs or Channels Only)'
			 GROUP BY ClientServicesRef,StartDate,Cell) s
		LEFT JOIN (SELECT ClientServicesRef,StartDate,AVG(Margin) Margin, AVG(r.Override_Pct_of_CBP) OverridePct
				 FROM Warehouse.MI.CampaignDetailsWave_PartnerLookup w
				 INNER JOIN Warehouse.Relational.Master_Retailer_Table r ON r.PartnerID=w.PartnerID
				 GROUP BY ClientServicesRef,StartDate) p
		ON p.ClientServicesRef=SUBSTRING(s.ClientServicesRef, 0, ISNULL(NULLIF(charindex('Bespoke', s.ClientServicesRef, 0), 0), 99))  AND p.StartDate=@SDate 
		LEFT JOIN (SELECT ClientServicesRef,StartDate,Cell, SUM(Cardholders_C) ControlGroupSize, SUM(IncrementalSales) IncrementalSales, 
				SUM(IncrementalTransactions) IncrementalTransactions, SUM(IncrementalSpenders) IncrementalSpenders,
				SUM(ExtraCommissionGenerated) CampaignCost,SUM(ExtraOverrideGenerated) IncrementalOverride -- Extra on the top of base offer
				FROM (SELECT * FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete UNION SELECT * FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete) a
				WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level='Bespoke Total'
				AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Main Results (Qualifying MIDs or Channels Only)'
				GROUP BY ClientServicesRef,StartDate,Cell) m
		ON m.ClientServicesRef=s.ClientServicesRef AND m.StartDate=s.StartDate AND m.Cell=s.Cell
		LEFT JOIN (SELECT ClientServicesRef,StartDate,Cell, 
				AVG(SPC_PooledStdDev) PooledStdDevSPC, AVG(SPC_DegreesOfFreedom) DegreesOfFreedomSPC,
				AVG(RR_PooledStdDev) PooledStdDevRR, AVG(RR_DegreesOfFreedom) DegreesOfFreedomRR, 
				AVG(SPS_PooledStdDev) PooledStdDevSPS, AVG(SPS_DegreesOfFreedom) DegreesOfFreedomSPS 
				FROM (SELECT * FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete UNION SELECT * FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete) a
				WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level='Bespoke Total'
				AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Main Results (Qualifying MIDs or Channels Only)'
				GROUP BY ClientServicesRef,StartDate,Cell) mstd
		ON mstd.ClientServicesRef=s.ClientServicesRef AND mstd.StartDate=s.StartDate AND mstd.Cell=s.Cell 
		LEFT JOIN (SELECT ClientServicesRef,StartDate,Cell, SUM(Sales_M) QualyfingSales, SUM(IncrementalSales) IncrementalQualyfingSales, 
				SUM(Cashback_M) QualyfingCashback
				FROM (SELECT * FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete UNION SELECT * FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete) a
				WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level='Bespoke Total'
				AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Above Spend Threshold'
				GROUP BY ClientServicesRef,StartDate,Cell) q
		ON q.ClientServicesRef=s.ClientServicesRef AND q.StartDate=s.StartDate AND q.Cell=s.Cell
		WHERE s.Cardholders>0
    
			 -- Uplif calculations
			 UPDATE Warehouse.MI.CampaignInternalResultsFinalWave_BespokeCell_Incomplete
			 SET SalesUplift=CASE WHEN IncrementalSales<Sales THEN 1.0*IncrementalSales/(Sales-IncrementalSales) ELSE IncrementalSales END
			   ,RRUplift=CASE WHEN IncrementalSpenders<Spenders THEN 1.0*IncrementalSpenders/(Sales-IncrementalSpenders) ELSE IncrementalSpenders END
			   ,ATVUplift=CASE WHEN IncrementalTransactions<Transactions AND IncrementalSales<Sales AND Transactions>0 THEN (1.0*Sales/Transactions)/(1.0*(Sales-IncrementalSales)/(Transactions-IncrementalTransactions))-1.0 ELSE 0 END
			   ,ATFUplift=CASE WHEN IncrementalSpenders<Spenders AND IncrementalTransactions<Transactions AND Spenders>0 THEN (1.0*Transactions/Spenders)/(1.0*(Transactions-IncrementalTransactions)/(Spenders-IncrementalSpenders))-1.0 ELSE 0 END
			   ,SPS_Diff=CASE WHEN IncrementalSpenders<Spenders AND IncrementalSales<Sales AND Spenders>0 THEN (1.0*Sales/Spenders)-(1.0*(Sales-IncrementalSales)/(Spenders-IncrementalSpenders)) ELSE 0 END
			 WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

			 UPDATE Warehouse.MI.CampaignInternalResultsFinalWave_BespokeCell_Incomplete
			 SET MainDriver=CASE WHEN SalesUplift<=0 THEN 'N/A'
							 WHEN RRUplift>=ATVUplift AND RRUplift>=ATFUplift THEN 'RR'
							 WHEN ATVUplift>=ATFUplift THEN 'ATV' ELSE 'ATF' END
			 WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

			 UPDATE Warehouse.MI.CampaignInternalResultsFinalWave_BespokeCell_Incomplete SET
			 TScoreSPC=CASE WHEN PooledStdDevSPC>0 THEN ABS(1.0*IncrementalSales/Cardholders)/PooledStdDevSPC ELSE 0 END,
			 TScoreRR=CASE WHEN PooledStdDevRR>0 THEN ABS(1.0*IncrementalSpenders/Cardholders)/PooledStdDevRR ELSE 0 END,
			 TScoreSPS=CASE WHEN PooledStdDevSPS>0 THEN ABS(1.0*SPS_Diff)/PooledStdDevSPS ELSE 0 END
			 WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
    
			-- Significance calculations
			 UPDATE Warehouse.MI.CampaignInternalResultsFinalWave_BespokeCell_Incomplete SET
			 PValueSPC=CASE WHEN TScoreSPC>=Probability_01 THEN 0.01 
						  WHEN TScoreSPC>=Probability_02 THEN 0.02
						  WHEN TScoreSPC>=Probability_05 THEN 0.05
						  WHEN TScoreSPC>=Probability_10 THEN 0.10
						  WHEN TScoreSPC>=Probability_20 THEN 0.20
						  WHEN TScoreSPC>=Probability_30 THEN 0.30
						  WHEN TScoreSPC>=Probability_40 THEN 0.40
						  WHEN TScoreSPC>=Probability_50 THEN 0.50
						  ELSE 1 END,
			 SignificantUpliftSPC=CASE WHEN TScoreSPC>=Probability_05 THEN 'High'
						  WHEN  TScoreSPC>=Probability_20 THEN 'Moderate'
						  ELSE 'No' END
			 FROM Warehouse.MI.CampaignInternalResultsFinalWave_BespokeCell_Incomplete w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomSPC
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomSPC) and t.Tailes=2
			 WHERE w.ClientServicesRef=@ClientServicesRef AND w.StartDate=@StartDate
    
			 UPDATE Warehouse.MI.CampaignInternalResultsFinalWave_BespokeCell_Incomplete SET
			 PValueRR=CASE WHEN TScoreRR>=Probability_01 THEN 0.01 
						  WHEN TScoreRR>=Probability_02 THEN 0.02
						  WHEN TScoreRR>=Probability_05 THEN 0.05
						  WHEN TScoreRR>=Probability_10 THEN 0.10
						  WHEN TScoreRR>=Probability_20 THEN 0.20
						  WHEN TScoreRR>=Probability_30 THEN 0.30
						  WHEN TScoreRR>=Probability_40 THEN 0.40
						  WHEN TScoreRR>=Probability_50 THEN 0.50
						  ELSE 1 END,
			 SignificantUpliftRR=CASE WHEN TScoreRR>=Probability_05 THEN 'High'
						  WHEN  TScoreRR>=Probability_20 THEN 'Moderate'
						  ELSE 'No' END
			 FROM Warehouse.MI.CampaignInternalResultsFinalWave_BespokeCell_Incomplete w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomRR
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomRR) and t.Tailes=2
			 WHERE w.ClientServicesRef=@ClientServicesRef AND w.StartDate=@StartDate

			 UPDATE Warehouse.MI.CampaignInternalResultsFinalWave_BespokeCell_Incomplete SET
			 PValueSPS=CASE WHEN TScoreSPS>=Probability_01 THEN 0.01 
						  WHEN TScoreSPS>=Probability_02 THEN 0.02
						  WHEN TScoreSPS>=Probability_05 THEN 0.05
						  WHEN TScoreSPS>=Probability_10 THEN 0.10
						  WHEN TScoreSPS>=Probability_20 THEN 0.20
						  WHEN TScoreSPS>=Probability_30 THEN 0.30
						  WHEN TScoreSPS>=Probability_40 THEN 0.40
						  WHEN TScoreSPS>=Probability_50 THEN 0.50
						  ELSE 1 END,
			 SignificantUpliftSPS=CASE WHEN TScoreSPS>=Probability_05 THEN 'High'
						  WHEN  TScoreSPS>=Probability_20 THEN 'Moderate'
						  ELSE 'No' END
			 FROM Warehouse.MI.CampaignInternalResultsFinalWave_BespokeCell_Incomplete w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomSPS
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomSPS) and t.Tailes=2
			 WHERE w.ClientServicesRef=@ClientServicesRef AND w.StartDate=@StartDate

 		-- Populate CampaignInternalResultsFinalWave_Segment (delete old entries first)   
    		DELETE FROM Warehouse.MI.CampaignInternalResultsFinalWave_Segment_Incomplete
		WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

		INSERT INTO Warehouse.MI.CampaignInternalResultsFinalWave_Segment_Incomplete
		(ClientServicesRef,StartDate, SegmentID, ControlGroup,
		CustomerUniverse,Level,
		ControlGroupSize,Cardholders,Sales,Transactions,Spenders,
		IncrementalSales,IncrementalMargin,
		IncrementalTransactions,IncrementalSpenders,
		PooledStdDevSPC,DegreesOfFreedomSPC,
		PooledStdDevRR,DegreesOfFreedomRR,
		PooledStdDevSPS,DegreesOfFreedomSPS,
		QualyfingSales, 
		Cashback,QualyfingCashback,
		Commission,CampaignCost,
		RewardOverride, IncrementalOverride)
		SELECT DISTINCT s.ClientServicesRef, s.StartDate, s.SegmentID, 
		@ControlGroup,@CustomerUniverse, 'Segment',
		COALESCE(m.ControlGroupSize,0), s.Cardholders, s.Sales, s.Transactions, s.Spenders,	 
		Stratification.least(COALESCE(m.IncrementalSales,0),s.Sales),Stratification.least(COALESCE(m.IncrementalSales,0),s.Sales)*p.Margin,
		Stratification.least(COALESCE(m.IncrementalTransactions,0),s.Transactions),Stratification.least(COALESCE(m.IncrementalSpenders,0),s.Spenders),
		mstd.PooledStdDevSPC,mstd.DegreesOfFreedomSPC,
		mstd.PooledStdDevRR,mstd.DegreesOfFreedomRR,
		mstd.PooledStdDevSPS,mstd.DegreesOfFreedomSPS,
		COALESCE(q.QualyfingSales,s.Sales),
		s.Cashback,COALESCE(q.QualyfingCashback,s.Cashback),
		s.Commission,m.CampaignCost,
		s.RewardOverride, m.IncrementalOverride	
		FROM (SELECT ClientServicesRef,StartDate,SegmentID, SUM(Cardholders) Cardholders, SUM(Sales) Sales, SUM(Transactions) Transactions, SUM(Spenders) Spenders,
			 SUM(Cashback) Cashback, SUM(Commission) Commission, 
			 SUM(RewardOverride) RewardOverride
			 FROM (SELECT * FROM Warehouse.MI.CampaignInternalResults_PureSales_Incomplete UNION SELECT * FROM Warehouse.MI.CampaignExternalResults_PureSales_Incomplete) a
			 WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level='Segment'
			 AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Main Results (Qualifying MIDs or Channels Only)'
			 GROUP BY ClientServicesRef,StartDate,SegmentID) s
		LEFT JOIN (SELECT ClientServicesRef,StartDate,AVG(Margin) Margin, AVG(r.Override_Pct_of_CBP) OverridePct
				 FROM Warehouse.MI.CampaignDetailsWave_PartnerLookup w
				 INNER JOIN Warehouse.Relational.Master_Retailer_Table r ON r.PartnerID=w.PartnerID
				 GROUP BY ClientServicesRef,StartDate) p
		ON p.ClientServicesRef=SUBSTRING(s.ClientServicesRef, 0, ISNULL(NULLIF(charindex('Bespoke', s.ClientServicesRef, 0), 0), 99)) AND p.StartDate=@SDate  
		LEFT JOIN (SELECT ClientServicesRef,StartDate,SegmentID, SUM(Cardholders_C) ControlGroupSize, SUM(IncrementalSales) IncrementalSales, 
				SUM(IncrementalTransactions) IncrementalTransactions, SUM(IncrementalSpenders) IncrementalSpenders,
				SUM(ExtraCommissionGenerated) CampaignCost,SUM(ExtraOverrideGenerated) IncrementalOverride -- Extra on the top of base offer
				FROM (SELECT * FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete UNION SELECT * FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete) a
				WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level='Segment'
				AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Main Results (Qualifying MIDs or Channels Only)'
				GROUP BY ClientServicesRef,StartDate,SegmentID) m
		ON m.ClientServicesRef=s.ClientServicesRef AND m.StartDate=s.StartDate AND m.SegmentID=s.SegmentID
		LEFT JOIN (SELECT ClientServicesRef,StartDate,SegmentID, 
				AVG(SPC_PooledStdDev) PooledStdDevSPC, AVG(SPC_DegreesOfFreedom) DegreesOfFreedomSPC,
				AVG(RR_PooledStdDev) PooledStdDevRR, AVG(RR_DegreesOfFreedom) DegreesOfFreedomRR, 
				AVG(SPS_PooledStdDev) PooledStdDevSPS, AVG(SPS_DegreesOfFreedom) DegreesOfFreedomSPS 
				FROM (SELECT * FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete UNION SELECT * FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete) a
				WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level='Segment'
				AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Main Results (Qualifying MIDs or Channels Only)'
				GROUP BY ClientServicesRef,StartDate,SegmentID) mstd
		ON mstd.ClientServicesRef=s.ClientServicesRef AND mstd.StartDate=s.StartDate AND mstd.SegmentID=s.SegmentID 
		LEFT JOIN (SELECT ClientServicesRef,StartDate,SegmentID, SUM(Sales_M) QualyfingSales, SUM(IncrementalSales) IncrementalQualyfingSales, 
				SUM(Cashback_M) QualyfingCashback
				FROM (SELECT * FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete UNION SELECT * FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete) a
				WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level='Segment'
				AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Above Spend Threshold'
				GROUP BY ClientServicesRef,StartDate,SegmentID) q
		ON q.ClientServicesRef=s.ClientServicesRef AND q.StartDate=s.StartDate AND q.SegmentID=s.SegmentID
		WHERE s.Cardholders>0
    
			 -- Uplif calculations
			 UPDATE Warehouse.MI.CampaignInternalResultsFinalWave_Segment_Incomplete
			 SET SalesUplift=CASE WHEN IncrementalSales<Sales THEN 1.0*IncrementalSales/(Sales-IncrementalSales) ELSE IncrementalSales END
			   ,RRUplift=CASE WHEN IncrementalSpenders<Spenders THEN 1.0*IncrementalSpenders/(Sales-IncrementalSpenders) ELSE IncrementalSpenders END
			   ,ATVUplift=CASE WHEN IncrementalTransactions<Transactions AND IncrementalSales<Sales AND Transactions>0 THEN (1.0*Sales/Transactions)/(1.0*(Sales-IncrementalSales)/(Transactions-IncrementalTransactions))-1.0 ELSE 0 END
			   ,ATFUplift=CASE WHEN IncrementalSpenders<Spenders AND IncrementalTransactions<Transactions AND Spenders>0 THEN (1.0*Transactions/Spenders)/(1.0*(Transactions-IncrementalTransactions)/(Spenders-IncrementalSpenders))-1.0 ELSE 0 END
			   ,SPS_Diff=CASE WHEN IncrementalSpenders<Spenders AND IncrementalSales<Sales AND Spenders>0 THEN (1.0*Sales/Spenders)-(1.0*(Sales-IncrementalSales)/(Spenders-IncrementalSpenders)) ELSE 0 END
			 WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

			 UPDATE Warehouse.MI.CampaignInternalResultsFinalWave_Segment_Incomplete
			 SET MainDriver=CASE WHEN SalesUplift<=0 THEN 'N/A'
							 WHEN RRUplift>=ATVUplift AND RRUplift>=ATFUplift THEN 'RR'
							 WHEN ATVUplift>=ATFUplift THEN 'ATV' ELSE 'ATF' END
			 WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

			 UPDATE Warehouse.MI.CampaignInternalResultsFinalWave_Segment_Incomplete SET
			 TScoreSPC=CASE WHEN PooledStdDevSPC>0 THEN ABS(1.0*IncrementalSales/Cardholders)/PooledStdDevSPC ELSE 0 END,
			 TScoreRR=CASE WHEN PooledStdDevRR>0 THEN ABS(1.0*IncrementalSpenders/Cardholders)/PooledStdDevRR ELSE 0 END,
			 TScoreSPS=CASE WHEN PooledStdDevSPS>0 THEN ABS(1.0*SPS_Diff)/PooledStdDevSPS ELSE 0 END
			 WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
    
			-- Significance calculations
			 UPDATE Warehouse.MI.CampaignInternalResultsFinalWave_Segment_Incomplete SET
			 PValueSPC=CASE WHEN TScoreSPC>=Probability_01 THEN 0.01 
						  WHEN TScoreSPC>=Probability_02 THEN 0.02
						  WHEN TScoreSPC>=Probability_05 THEN 0.05
						  WHEN TScoreSPC>=Probability_10 THEN 0.10
						  WHEN TScoreSPC>=Probability_20 THEN 0.20
						  WHEN TScoreSPC>=Probability_30 THEN 0.30
						  WHEN TScoreSPC>=Probability_40 THEN 0.40
						  WHEN TScoreSPC>=Probability_50 THEN 0.50
						  ELSE 1 END,
			 SignificantUpliftSPC=CASE WHEN TScoreSPC>=Probability_05 THEN 'High'
						  WHEN  TScoreSPC>=Probability_20 THEN 'Moderate'
						  ELSE 'No' END
			 FROM Warehouse.MI.CampaignInternalResultsFinalWave_Segment_Incomplete w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomSPC
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomSPC) and t.Tailes=2
			 WHERE w.ClientServicesRef=@ClientServicesRef AND w.StartDate=@StartDate
    
			 UPDATE Warehouse.MI.CampaignInternalResultsFinalWave_Segment_Incomplete SET
			 PValueRR=CASE WHEN TScoreRR>=Probability_01 THEN 0.01 
						  WHEN TScoreRR>=Probability_02 THEN 0.02
						  WHEN TScoreRR>=Probability_05 THEN 0.05
						  WHEN TScoreRR>=Probability_10 THEN 0.10
						  WHEN TScoreRR>=Probability_20 THEN 0.20
						  WHEN TScoreRR>=Probability_30 THEN 0.30
						  WHEN TScoreRR>=Probability_40 THEN 0.40
						  WHEN TScoreRR>=Probability_50 THEN 0.50
						  ELSE 1 END,
			 SignificantUpliftRR=CASE WHEN TScoreRR>=Probability_05 THEN 'High'
						  WHEN  TScoreRR>=Probability_20 THEN 'Moderate'
						  ELSE 'No' END
			 FROM Warehouse.MI.CampaignInternalResultsFinalWave_Segment_Incomplete w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomRR
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomRR) and t.Tailes=2
			 WHERE w.ClientServicesRef=@ClientServicesRef AND w.StartDate=@StartDate

			 UPDATE Warehouse.MI.CampaignInternalResultsFinalWave_Segment_Incomplete SET
			 PValueSPS=CASE WHEN TScoreSPS>=Probability_01 THEN 0.01 
						  WHEN TScoreSPS>=Probability_02 THEN 0.02
						  WHEN TScoreSPS>=Probability_05 THEN 0.05
						  WHEN TScoreSPS>=Probability_10 THEN 0.10
						  WHEN TScoreSPS>=Probability_20 THEN 0.20
						  WHEN TScoreSPS>=Probability_30 THEN 0.30
						  WHEN TScoreSPS>=Probability_40 THEN 0.40
						  WHEN TScoreSPS>=Probability_50 THEN 0.50
						  ELSE 1 END,
			 SignificantUpliftSPS=CASE WHEN TScoreSPS>=Probability_05 THEN 'High'
						  WHEN  TScoreSPS>=Probability_20 THEN 'Moderate'
						  ELSE 'No' END
			 FROM Warehouse.MI.CampaignInternalResultsFinalWave_Segment_Incomplete w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomSPS
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomSPS) and t.Tailes=2
			 WHERE w.ClientServicesRef=@ClientServicesRef AND w.StartDate=@StartDate

 		-- Populate CampaignInternalResultsFinalWave_SuperSegment (delete old entries first)   
    		DELETE FROM Warehouse.MI.CampaignInternalResultsFinalWave_SuperSegment_Incomplete
		WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

		INSERT INTO Warehouse.MI.CampaignInternalResultsFinalWave_SuperSegment_Incomplete
		(ClientServicesRef,StartDate, SegmentID, ControlGroup,
		CustomerUniverse,Level,
		ControlGroupSize,Cardholders,Sales,Transactions,Spenders,
		IncrementalSales,IncrementalMargin,
		IncrementalTransactions,IncrementalSpenders,
		PooledStdDevSPC,DegreesOfFreedomSPC,
		PooledStdDevRR,DegreesOfFreedomRR,
		PooledStdDevSPS,DegreesOfFreedomSPS,
		QualyfingSales, 
		Cashback,QualyfingCashback,
		Commission,CampaignCost,
		RewardOverride, IncrementalOverride)
		SELECT DISTINCT s.ClientServicesRef, s.StartDate, s.SegmentID, 
		@ControlGroup,@CustomerUniverse, 'SuperSegment',
		COALESCE(m.ControlGroupSize,0), s.Cardholders, s.Sales, s.Transactions, s.Spenders,	 
		Stratification.least(COALESCE(m.IncrementalSales,0),s.Sales),Stratification.least(COALESCE(m.IncrementalSales,0),s.Sales)*p.Margin,
		Stratification.least(COALESCE(m.IncrementalTransactions,0),s.Transactions),Stratification.least(COALESCE(m.IncrementalSpenders,0),s.Spenders),
		mstd.PooledStdDevSPC,mstd.DegreesOfFreedomSPC,
		mstd.PooledStdDevRR,mstd.DegreesOfFreedomRR,
		mstd.PooledStdDevSPS,mstd.DegreesOfFreedomSPS,
		COALESCE(q.QualyfingSales,s.Sales),
		s.Cashback,COALESCE(q.QualyfingCashback,s.Cashback),
		s.Commission,m.CampaignCost,
		s.RewardOverride, m.IncrementalOverride	
		FROM (SELECT ClientServicesRef,StartDate,SegmentID, SUM(Cardholders) Cardholders, SUM(Sales) Sales, SUM(Transactions) Transactions, SUM(Spenders) Spenders,
			 SUM(Cashback) Cashback, SUM(Commission) Commission, 
			 SUM(RewardOverride) RewardOverride
			 FROM (SELECT * FROM Warehouse.MI.CampaignInternalResults_PureSales_Incomplete UNION SELECT * FROM Warehouse.MI.CampaignExternalResults_PureSales_Incomplete) a
			 WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level='SuperSegment'
			 AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Main Results (Qualifying MIDs or Channels Only)'
			 GROUP BY ClientServicesRef,StartDate,SegmentID) s
		LEFT JOIN (SELECT ClientServicesRef,StartDate,AVG(Margin) Margin, AVG(r.Override_Pct_of_CBP) OverridePct
				 FROM Warehouse.MI.CampaignDetailsWave_PartnerLookup w
				 INNER JOIN Warehouse.Relational.Master_Retailer_Table r ON r.PartnerID=w.PartnerID
				 GROUP BY ClientServicesRef,StartDate) p
		ON p.ClientServicesRef=SUBSTRING(s.ClientServicesRef, 0, ISNULL(NULLIF(charindex('Bespoke', s.ClientServicesRef, 0), 0), 99)) AND p.StartDate=@SDate  
		LEFT JOIN (SELECT ClientServicesRef,StartDate,SegmentID, SUM(Cardholders_C) ControlGroupSize, SUM(IncrementalSales) IncrementalSales, 
				SUM(IncrementalTransactions) IncrementalTransactions, SUM(IncrementalSpenders) IncrementalSpenders,
				SUM(ExtraCommissionGenerated) CampaignCost,SUM(ExtraOverrideGenerated) IncrementalOverride -- Extra on the top of base offer
				FROM (SELECT * FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete UNION SELECT * FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete) a
				WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level='SuperSegment'
				AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Main Results (Qualifying MIDs or Channels Only)'
				GROUP BY ClientServicesRef,StartDate,SegmentID) m
		ON m.ClientServicesRef=s.ClientServicesRef AND m.StartDate=s.StartDate AND m.SegmentID=s.SegmentID
		LEFT JOIN (SELECT ClientServicesRef,StartDate,SegmentID, 
				AVG(SPC_PooledStdDev) PooledStdDevSPC, AVG(SPC_DegreesOfFreedom) DegreesOfFreedomSPC,
				AVG(RR_PooledStdDev) PooledStdDevRR, AVG(RR_DegreesOfFreedom) DegreesOfFreedomRR, 
				AVG(SPS_PooledStdDev) PooledStdDevSPS, AVG(SPS_DegreesOfFreedom) DegreesOfFreedomSPS 
				FROM (SELECT * FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete UNION SELECT * FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete) a
				WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level='SuperSegment'
				AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Main Results (Qualifying MIDs or Channels Only)'
				GROUP BY ClientServicesRef,StartDate,SegmentID) mstd
		ON mstd.ClientServicesRef=s.ClientServicesRef AND mstd.StartDate=s.StartDate AND mstd.SegmentID=s.SegmentID     
		LEFT JOIN (SELECT ClientServicesRef,StartDate,SegmentID, SUM(Sales_M) QualyfingSales, SUM(IncrementalSales) IncrementalQualyfingSales, 
				SUM(Cashback_M) QualyfingCashback
				FROM (SELECT * FROM Warehouse.MI.CampaignInternalResults_Workings_Incomplete UNION SELECT * FROM Warehouse.MI.CampaignExternalResults_Workings_Incomplete) a
				WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level='SuperSegment'
				AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Above Spend Threshold'
				GROUP BY ClientServicesRef,StartDate,SegmentID) q
		ON q.ClientServicesRef=s.ClientServicesRef AND q.StartDate=s.StartDate AND q.SegmentID=s.SegmentID
		WHERE s.Cardholders>0
    
			 -- Uplif calculations
			 UPDATE Warehouse.MI.CampaignInternalResultsFinalWave_SuperSegment_Incomplete
			 SET SalesUplift=CASE WHEN IncrementalSales<Sales THEN 1.0*IncrementalSales/(Sales-IncrementalSales) ELSE IncrementalSales END
			   ,RRUplift=CASE WHEN IncrementalSpenders<Spenders THEN 1.0*IncrementalSpenders/(Sales-IncrementalSpenders) ELSE IncrementalSpenders END
			   ,ATVUplift=CASE WHEN IncrementalTransactions<Transactions AND IncrementalSales<Sales AND Transactions>0 THEN (1.0*Sales/Transactions)/(1.0*(Sales-IncrementalSales)/(Transactions-IncrementalTransactions))-1.0 ELSE 0 END
			   ,ATFUplift=CASE WHEN IncrementalSpenders<Spenders AND IncrementalTransactions<Transactions AND Spenders>0 THEN (1.0*Transactions/Spenders)/(1.0*(Transactions-IncrementalTransactions)/(Spenders-IncrementalSpenders))-1.0 ELSE 0 END
			   ,SPS_Diff=CASE WHEN IncrementalSpenders<Spenders AND IncrementalSales<Sales AND Spenders>0 THEN (1.0*Sales/Spenders)-(1.0*(Sales-IncrementalSales)/(Spenders-IncrementalSpenders)) ELSE 0 END
			 WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

			 UPDATE Warehouse.MI.CampaignInternalResultsFinalWave_SuperSegment_Incomplete
			 SET MainDriver=CASE WHEN SalesUplift<=0 THEN 'N/A'
							 WHEN RRUplift>=ATVUplift AND RRUplift>=ATFUplift THEN 'RR'
							 WHEN ATVUplift>=ATFUplift THEN 'ATV' ELSE 'ATF' END
			 WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

			 UPDATE Warehouse.MI.CampaignInternalResultsFinalWave_SuperSegment_Incomplete SET
			 TScoreSPC=CASE WHEN PooledStdDevSPC>0 THEN ABS(1.0*IncrementalSales/Cardholders)/PooledStdDevSPC ELSE 0 END,
			 TScoreRR=CASE WHEN PooledStdDevRR>0 THEN ABS(1.0*IncrementalSpenders/Cardholders)/PooledStdDevRR ELSE 0 END,
			 TScoreSPS=CASE WHEN PooledStdDevSPS>0 THEN ABS(1.0*SPS_Diff)/PooledStdDevSPS ELSE 0 END
			 WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
    
			-- Significance calculations
			 UPDATE Warehouse.MI.CampaignInternalResultsFinalWave_SuperSegment_Incomplete SET
			 PValueSPC=CASE WHEN TScoreSPC>=Probability_01 THEN 0.01 
						  WHEN TScoreSPC>=Probability_02 THEN 0.02
						  WHEN TScoreSPC>=Probability_05 THEN 0.05
						  WHEN TScoreSPC>=Probability_10 THEN 0.10
						  WHEN TScoreSPC>=Probability_20 THEN 0.20
						  WHEN TScoreSPC>=Probability_30 THEN 0.30
						  WHEN TScoreSPC>=Probability_40 THEN 0.40
						  WHEN TScoreSPC>=Probability_50 THEN 0.50
						  ELSE 1 END,
			 SignificantUpliftSPC=CASE WHEN TScoreSPC>=Probability_05 THEN 'High'
						  WHEN  TScoreSPC>=Probability_20 THEN 'Moderate'
						  ELSE 'No' END
			 FROM Warehouse.MI.CampaignInternalResultsFinalWave_SuperSegment_Incomplete w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomSPC
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomSPC) and t.Tailes=2
			 WHERE w.ClientServicesRef=@ClientServicesRef AND w.StartDate=@StartDate
    
			 UPDATE Warehouse.MI.CampaignInternalResultsFinalWave_SuperSegment_Incomplete SET
			 PValueRR=CASE WHEN TScoreRR>=Probability_01 THEN 0.01 
						  WHEN TScoreRR>=Probability_02 THEN 0.02
						  WHEN TScoreRR>=Probability_05 THEN 0.05
						  WHEN TScoreRR>=Probability_10 THEN 0.10
						  WHEN TScoreRR>=Probability_20 THEN 0.20
						  WHEN TScoreRR>=Probability_30 THEN 0.30
						  WHEN TScoreRR>=Probability_40 THEN 0.40
						  WHEN TScoreRR>=Probability_50 THEN 0.50
						  ELSE 1 END,
			 SignificantUpliftRR=CASE WHEN TScoreRR>=Probability_05 THEN 'High'
						  WHEN  TScoreRR>=Probability_20 THEN 'Moderate'
						  ELSE 'No' END
			 FROM Warehouse.MI.CampaignInternalResultsFinalWave_SuperSegment_Incomplete w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomRR
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomRR) and t.Tailes=2
			 WHERE w.ClientServicesRef=@ClientServicesRef AND w.StartDate=@StartDate

			 UPDATE Warehouse.MI.CampaignInternalResultsFinalWave_SuperSegment_Incomplete SET
			 PValueSPS=CASE WHEN TScoreSPS>=Probability_01 THEN 0.01 
						  WHEN TScoreSPS>=Probability_02 THEN 0.02
						  WHEN TScoreSPS>=Probability_05 THEN 0.05
						  WHEN TScoreSPS>=Probability_10 THEN 0.10
						  WHEN TScoreSPS>=Probability_20 THEN 0.20
						  WHEN TScoreSPS>=Probability_30 THEN 0.30
						  WHEN TScoreSPS>=Probability_40 THEN 0.40
						  WHEN TScoreSPS>=Probability_50 THEN 0.50
						  ELSE 1 END,
			 SignificantUpliftSPS=CASE WHEN TScoreSPS>=Probability_05 THEN 'High'
						  WHEN  TScoreSPS>=Probability_20 THEN 'Moderate'
						  ELSE 'No' END
			 FROM Warehouse.MI.CampaignInternalResultsFinalWave_SuperSegment_Incomplete w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomSPS
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomSPS) and t.Tailes=2
			 WHERE w.ClientServicesRef=@ClientServicesRef AND w.StartDate=@StartDate

	   -- Log that Store Procedure did not return Error
	   UPDATE Warehouse.MI.Campaign_Log
	   SET ErrorMessage=0
	   WHERE ID=@MY_ID

    END

    -- Otherwise show error message 
    ELSE
    BEGIN
	   PRINT 'Wrong Parameters selected  for ' + COALESCE(@ClientServicesRef,'NULL') +' starting ' + CAST(COALESCE(@StartDate,'') AS VARCHAR) + ' (Control ' + COALESCE(@ControlGroup,'NULL') + ' ,  Universe ' + COALESCE(@CustomerUniverse,'NULL') + '  and Aggregation Level ' + COALESCE(@AggregationLevel,'NULL') + ').
Select different ones' 

	   -- Log that Store Procedure returned Error
	   UPDATE Warehouse.MI.Campaign_Log
	   SET ErrorMessage=1
	   WHERE ID=@MY_ID
    END



END

ELSE
BEGIN
    -- If not stored show error message 
    PRINT 'Calculations for ' + @ClientServicesRef +' starting ' + CAST(@StartDate AS VARCHAR) + ' were not calculated yet.
Run Store Procedure MI.CampaignInternalResults_Calculate first.' 

    -- Log that Store Procedure returned Error
    UPDATE Warehouse.MI.Campaign_Log
    SET ErrorMessage=1
    WHERE ID=@MY_ID
END

-- Log when Store Procedure finished running
UPDATE Warehouse.MI.Campaign_Log
SET RunEndTime=GETDATE()
WHERE ID=@MY_ID


END


