-- =============================================
-- Author:		Dorota
-- Create date:	15/06/2015
-- =============================================

CREATE PROCEDURE [MI].[CampaignResultsLTE_InternalFinalWave_Store] (@ClientServicesRef VARCHAR(25), @StartDate DATE, -- unhide this row to modify SP
@AggregationLevel VARCHAR(100)=NULL, @ExclusionsPercLimit DECIMAL(4,3)=0.1, @ExclusionsAbsLimit INT=10) AS -- unhide this row to modify SP

--DECLARE @ClientServicesRef VARCHAR(25); SET  @ClientServicesRef='SA001'; DECLARE @StartDate DATE; SET  @StartDate='2015-04-30'; -- unhide this row to run code once
--DECLARE @ExclusionsPercLimit DECIMAL(4,3)=0.1; DECLARE @ExclusionsAbsLimit INT=10; -- unhide this row to run code once
BEGIN 

-- Log when Store Procedure started running in CamapainResultsLTE_Log
INSERT INTO Warehouse.MI.Campaign_Log
(StoreProcedureName,  
Parameter_ClientServicesRef, Parameter_StartDate, 
RunByUser , RunStartTime)
SELECT 'CampaignResultsLTE_InternalFinalWave_Store', 
@ClientServicesRef, @StartDate, 
SYSTEM_USER, GETDATE()

-- Store RowID for curently running Store Procedure
DECLARE @MY_ID AS INT;
SET @MY_ID= (SELECT SCOPE_IDENTITY());

-- Check if ResultsLTE are already stored in working tables
IF (SELECT COUNT(*) FROM Warehouse.MI.CampaignInternalResultsLTE_Workings WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate)>0
	 OR (SELECT COUNT(*) FROM Warehouse.MI.CampaignExternalResultsLTE_Workings WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate)>0

BEGIN 

    -- Decide what Parameters to Use
    DECLARE @ControlGroup VARCHAR(100); 
    DECLARE @CustomerUniverse VARCHAR(100); 

    -- For Control Group and Universe use the same as in the main measurments
    SET @ControlGroup=(SELECT ControlGroup
    FROM Warehouse.MI.CampaignInternalResultsFinalWave
    WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate)

    SET @CustomerUniverse=(SELECT CustomerUniverse
    FROM Warehouse.MI.CampaignInternalResultsFinalWave
    WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate)

    -- Choose the lowest aggregation level (Bespoke Cell is prioritized over Segment/Supersegment over Total)
    IF @AggregationLevel IS NULL 
    BEGIN 
	   SET @AggregationLevel=(SELECT MIN(w.Level) FROM Warehouse.MI.CampaignInternalResultsLTE_Workings w
	   WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate 
	   AND CustomerUniverse=@CustomerUniverse AND ControlGroup=@ControlGroup) 
   END

    IF @AggregationLevel IS NULL 
    BEGIN 
	   SET @AggregationLevel=(SELECT MIN(w.Level) FROM Warehouse.MI.CampaignExternalResultsLTE_Workings w
	   WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate 
	   AND CustomerUniverse=@CustomerUniverse AND ControlGroup=@ControlGroup) 
   END

	   -- Check if ResultsLTE exist for selected @ControlGroup, @CustomerUniverse, @AggregationLevel parameters
	   IF (SELECT COUNT(*) FROM Warehouse.MI.CampaignExternalResultsLTE_Workings WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
		  AND ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level=@AggregationLevel)>0
	   OR (SELECT COUNT(*) FROM Warehouse.MI.CampaignInternalResultsLTE_Workings WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
		  AND ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level=@AggregationLevel)>0
 

    -- If everything ok, populates ResultsLTEFinal Table
    BEGIN 

	 	-- Populate CampaignInternalResultsLTEFinalWave (delete old entries first)
		DELETE FROM Warehouse.MI.CampaignInternalResultsLTEFinalWave
		WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

		INSERT INTO Warehouse.MI.CampaignInternalResultsLTEFinalWave
		(Effect,ClientServicesRef,StartDate,ControlGroup,
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
		RewardOverride, IncrementalOverride,
		UpliftCardholders_Perc,UpliftCardholders_BelowLimit)
		SELECT DISTINCT s.Effect,s.ClientServicesRef, s.StartDate, 
		@ControlGroup,@CustomerUniverse, @AggregationLevel,
		m.ControlGroupSize, s.Cardholders, s.Sales, s.Transactions, s.Spenders,	 
		CASE WHEN UpliftCardholders>=@ExclusionsAbsLimit AND UpliftCardholders>=@ExclusionsPercLimit*Cardholders
			THEN 1.0*Cardholders/UpliftCardholders ELSE 0 END
			*Stratification.least(COALESCE(m.IncrementalSales,0),s.Sales),
		CASE WHEN UpliftCardholders>=@ExclusionsAbsLimit AND UpliftCardholders>=@ExclusionsPercLimit*Cardholders
			THEN 1.0*Cardholders/UpliftCardholders ELSE 0 END
			*Stratification.least(COALESCE(m.IncrementalSales,0),s.Sales)*p.Margin,
		CASE WHEN UpliftCardholders>=@ExclusionsAbsLimit AND UpliftCardholders>=@ExclusionsPercLimit*Cardholders
			THEN 1.0*Cardholders/UpliftCardholders ELSE 0 END
			*Stratification.least(COALESCE(m.IncrementalTransactions,0),s.Transactions),
		CASE WHEN UpliftCardholders>=@ExclusionsAbsLimit AND UpliftCardholders>=@ExclusionsPercLimit*Cardholders
			THEN 1.0*Cardholders/UpliftCardholders ELSE 0 END
			*Stratification.least(COALESCE(m.IncrementalSpenders,0),s.Spenders),
		mstd.PooledStdDevSPC,mstd.DegreesOfFreedomSPC,
		mstd.PooledStdDevRR,mstd.DegreesOfFreedomRR,
		mstd.PooledStdDevSPS,mstd.DegreesOfFreedomSPS,
		COALESCE(q.QualyfingSales,s.Sales),
		s.Cashback,COALESCE(q.QualyfingCashback,s.Cashback),
		s.Commission,m.CampaignCost,
		s.RewardOverride, m.IncrementalOverride,
		1.0*COALESCE(UpliftCardholders,0)/s.Cardholders,
		CASE WHEN UpliftCardholders>=@ExclusionsAbsLimit AND UpliftCardholders>=@ExclusionsPercLimit*Cardholders
			THEN 1 ELSE 0 END UpliftCardholders_BelowLimit
		FROM (SELECT Effect,ClientServicesRef,StartDate, SUM(Cardholders) Cardholders, SUM(Sales) Sales, SUM(Transactions) Transactions, SUM(Spenders) Spenders,
			 SUM(Cashback) Cashback, SUM(Commission) Commission, 
			 SUM(RewardOverride) RewardOverride
			 FROM (SELECT * FROM Warehouse.MI.CampaignExternalResultsLTE_PureSales UNION SELECT * FROM Warehouse.MI.CampaignInternalResultsLTE_PureSales) a
			 WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level=@AggregationLevel
			 AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Main Results (Qualifying MIDs or Channels Only)'
			 GROUP BY Effect,ClientServicesRef,StartDate) s
		LEFT JOIN (SELECT ClientServicesRef,StartDate, AVG(Margin) Margin, AVG(r.Override_Pct_of_CBP) OverridePct
				 FROM Warehouse.MI.CampaignDetailsWave_PartnerLookup w
				 INNER JOIN Warehouse.Relational.Master_Retailer_Table r ON r.PartnerID=w.PartnerID
				 GROUP BY ClientServicesRef,StartDate) p
		ON p.ClientServicesRef=s.ClientServicesRef AND p.StartDate=s.StartDate   
		LEFT JOIN (SELECT Effect,ClientServicesRef,StartDate, SUM(Cardholders_M) UpliftCardholders, SUM(Cardholders_C) ControlGroupSize, SUM(IncrementalSales) IncrementalSales, 
				SUM(IncrementalTransactions) IncrementalTransactions, SUM(IncrementalSpenders) IncrementalSpenders,
				SUM(ExtraCommissionGenerated) CampaignCost,SUM(ExtraOverrideGenerated) IncrementalOverride -- Extra on the top of base offer
				FROM (SELECT * FROM Warehouse.MI.CampaignExternalResultsLTE_Workings UNION SELECT * FROM Warehouse.MI.CampaignInternalResultsLTE_Workings) a
				WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level=@AggregationLevel
				AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Main Results (Qualifying MIDs or Channels Only)'
				GROUP BY Effect,ClientServicesRef,StartDate) m
		ON m.ClientServicesRef=s.ClientServicesRef AND m.StartDate=s.StartDate AND m.Effect=s.Effect
		LEFT JOIN (SELECT Effect,ClientServicesRef,StartDate, 
				AVG(SPC_PooledStdDev) PooledStdDevSPC, AVG(SPC_DegreesOfFreedom) DegreesOfFreedomSPC,
				AVG(RR_PooledStdDev) PooledStdDevRR, AVG(RR_DegreesOfFreedom) DegreesOfFreedomRR, 
				AVG(SPS_PooledStdDev) PooledStdDevSPS, AVG(SPS_DegreesOfFreedom) DegreesOfFreedomSPS 
				FROM (SELECT * FROM Warehouse.MI.CampaignExternalResultsLTE_Workings UNION SELECT * FROM Warehouse.MI.CampaignInternalResultsLTE_Workings) a
				WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level='Total'
				AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Main Results (Qualifying MIDs or Channels Only)'
				GROUP BY Effect,ClientServicesRef,StartDate) mstd
		ON mstd.ClientServicesRef=s.ClientServicesRef AND mstd.StartDate=s.StartDate AND mstd.Effect=s.Effect    
		LEFT JOIN (SELECT Effect,ClientServicesRef,StartDate, SUM(Sales_M) QualyfingSales, SUM(IncrementalSales) IncrementalQualyfingSales, 
				SUM(Cashback_M) QualyfingCashback
				FROM (SELECT * FROM Warehouse.MI.CampaignExternalResultsLTE_Workings UNION SELECT * FROM Warehouse.MI.CampaignInternalResultsLTE_Workings) a
				WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level=@AggregationLevel
				AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Above Spend Threshold'
				GROUP BY Effect,ClientServicesRef,StartDate) q
		ON q.ClientServicesRef=s.ClientServicesRef AND q.StartDate=s.StartDate AND q.Effect=s.Effect 
		WHERE s.Cardholders>0
    
			 -- Uplif calculations
			 UPDATE Warehouse.MI.CampaignInternalResultsLTEFinalWave
			 SET SalesUplift=CASE WHEN IncrementalSales<Sales THEN 1.0*IncrementalSales/(Sales-IncrementalSales) ELSE IncrementalSales END
			   ,RRUplift=CASE WHEN IncrementalSpenders<Spenders THEN 1.0*IncrementalSpenders/(Sales-IncrementalSpenders) ELSE IncrementalSpenders END
			   ,ATVUplift=CASE WHEN IncrementalTransactions<Transactions AND IncrementalSales<Sales AND Transactions>0 THEN (1.0*Sales/Transactions)/(1.0*(Sales-IncrementalSales)/(Transactions-IncrementalTransactions))-1.0 ELSE 0 END
			   ,ATFUplift=CASE WHEN IncrementalSpenders<Spenders AND IncrementalTransactions<Transactions AND Spenders>0 THEN (1.0*Transactions/Spenders)/(1.0*(Transactions-IncrementalTransactions)/(Spenders-IncrementalSpenders))-1.0 ELSE 0 END
			   ,SPS_Diff=CASE WHEN IncrementalSpenders<Spenders AND IncrementalSales<Sales AND Spenders>0 THEN (1.0*Sales/Spenders)-(1.0*(Sales-IncrementalSales)/(Spenders-IncrementalSpenders)) ELSE 0 END
			 WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

			 UPDATE Warehouse.MI.CampaignInternalResultsLTEFinalWave
			 SET MainDriver=CASE WHEN SalesUplift<=0 THEN 'N/A'
							 WHEN RRUplift>=ATVUplift AND RRUplift>=ATFUplift THEN 'RR'
							 WHEN ATVUplift>=ATFUplift THEN 'ATV' ELSE 'ATF' END
			 WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

			 UPDATE Warehouse.MI.CampaignInternalResultsLTEFinalWave SET
			 TScoreSPC=CASE WHEN PooledStdDevSPC>0 THEN ABS(1.0*IncrementalSales/Cardholders)/PooledStdDevSPC ELSE 0 END,
			 TScoreRR=CASE WHEN PooledStdDevRR>0 THEN ABS(1.0*IncrementalSpenders/Cardholders)/PooledStdDevRR ELSE 0 END,
			 TScoreSPS=CASE WHEN PooledStdDevSPS>0 THEN ABS(1.0*SPS_Diff)/PooledStdDevSPS ELSE 0 END
			 WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
    
			-- Significance calculations
			 UPDATE Warehouse.MI.CampaignInternalResultsLTEFinalWave SET
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
			 FROM Warehouse.MI.CampaignInternalResultsLTEFinalWave w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomSPC
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomSPC) and t.Tailes=2
			 WHERE w.ClientServicesRef=@ClientServicesRef AND w.StartDate=@StartDate
    
			 UPDATE Warehouse.MI.CampaignInternalResultsLTEFinalWave SET
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
			 FROM Warehouse.MI.CampaignInternalResultsLTEFinalWave w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomRR
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomRR) and t.Tailes=2
			 WHERE w.ClientServicesRef=@ClientServicesRef AND w.StartDate=@StartDate

			 UPDATE Warehouse.MI.CampaignInternalResultsLTEFinalWave SET
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
			 FROM Warehouse.MI.CampaignInternalResultsLTEFinalWave w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomSPS
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomSPS) and t.Tailes=2
			 WHERE w.ClientServicesRef=@ClientServicesRef AND w.StartDate=@StartDate

 		-- Populate CampaignInternalResultsLTEFinalWave_BespokeCell (delete old entries first)   
    		DELETE FROM Warehouse.MI.CampaignInternalResultsLTEFinalWave_BespokeCell
		WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

		INSERT INTO Warehouse.MI.CampaignInternalResultsLTEFinalWave_BespokeCell
		(Effect,ClientServicesRef,StartDate, Cell, ControlGroup,
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
		RewardOverride, IncrementalOverride,
		UpliftCardholders_Perc,UpliftCardholders_BelowLimit)
		SELECT DISTINCT s.Effect,s.ClientServicesRef, s.StartDate, s.Cell, 
		@ControlGroup,@CustomerUniverse, 'Bespoke Total',
		m.ControlGroupSize, s.Cardholders, s.Sales, s.Transactions, s.Spenders,	 
		CASE WHEN UpliftCardholders>=@ExclusionsAbsLimit AND UpliftCardholders>=@ExclusionsPercLimit*Cardholders
			THEN 1.0*Cardholders/UpliftCardholders ELSE 0 END
			*Stratification.least(COALESCE(m.IncrementalSales,0),s.Sales),
		CASE WHEN UpliftCardholders>=@ExclusionsAbsLimit AND UpliftCardholders>=@ExclusionsPercLimit*Cardholders
			THEN 1.0*Cardholders/UpliftCardholders ELSE 0 END
			*Stratification.least(COALESCE(m.IncrementalSales,0),s.Sales)*p.Margin,
		CASE WHEN UpliftCardholders>=@ExclusionsAbsLimit AND UpliftCardholders>=@ExclusionsPercLimit*Cardholders
			THEN 1.0*Cardholders/UpliftCardholders ELSE 0 END
			*Stratification.least(COALESCE(m.IncrementalTransactions,0),s.Transactions),
		CASE WHEN UpliftCardholders>=@ExclusionsAbsLimit AND UpliftCardholders>=@ExclusionsPercLimit*Cardholders
			THEN 1.0*Cardholders/UpliftCardholders ELSE 0 END
			*Stratification.least(COALESCE(m.IncrementalSpenders,0),s.Spenders),
		mstd.PooledStdDevSPC,mstd.DegreesOfFreedomSPC,
		mstd.PooledStdDevRR,mstd.DegreesOfFreedomRR,
		mstd.PooledStdDevSPS,mstd.DegreesOfFreedomSPS,
		COALESCE(q.QualyfingSales,s.Sales),
		s.Cashback,COALESCE(q.QualyfingCashback,s.Cashback),
		s.Commission,m.CampaignCost,
		s.RewardOverride, m.IncrementalOverride,
		1.0*COALESCE(UpliftCardholders,0)/s.Cardholders,
		CASE WHEN UpliftCardholders>=@ExclusionsAbsLimit AND UpliftCardholders>=@ExclusionsPercLimit*Cardholders
			THEN 1 ELSE 0 END UpliftCardholders_BelowLimit
		FROM (SELECT Effect,ClientServicesRef,StartDate,Cell, SUM(Cardholders) Cardholders, SUM(Sales) Sales, SUM(Transactions) Transactions, SUM(Spenders) Spenders,
			 SUM(Cashback) Cashback, SUM(Commission) Commission, 
			 SUM(RewardOverride) RewardOverride
			 FROM (SELECT * FROM Warehouse.MI.CampaignExternalResultsLTE_PureSales UNION SELECT * FROM Warehouse.MI.CampaignInternalResultsLTE_PureSales) a
			 WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level='Bespoke Total'
			 AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Main Results (Qualifying MIDs or Channels Only)'
			 GROUP BY Effect,ClientServicesRef,StartDate,Cell) s
		LEFT JOIN (SELECT ClientServicesRef,StartDate,AVG(Margin) Margin, AVG(r.Override_Pct_of_CBP) OverridePct
				 FROM Warehouse.MI.CampaignDetailsWave_PartnerLookup w
				 INNER JOIN Warehouse.Relational.Master_Retailer_Table r ON r.PartnerID=w.PartnerID
				 GROUP BY ClientServicesRef,StartDate) p
		ON p.ClientServicesRef=s.ClientServicesRef AND p.StartDate=s.StartDate
		LEFT JOIN (SELECT Effect,ClientServicesRef,StartDate,Cell, SUM(Cardholders_M) UpliftCardholders, SUM(Cardholders_C) ControlGroupSize, SUM(IncrementalSales) IncrementalSales, 
				SUM(IncrementalTransactions) IncrementalTransactions, SUM(IncrementalSpenders) IncrementalSpenders,
				SUM(ExtraCommissionGenerated) CampaignCost,SUM(ExtraOverrideGenerated) IncrementalOverride -- Extra on the top of base offer
				FROM (SELECT * FROM Warehouse.MI.CampaignExternalResultsLTE_Workings UNION SELECT * FROM Warehouse.MI.CampaignInternalResultsLTE_Workings) a
				WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level='Bespoke Total'
				AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Main Results (Qualifying MIDs or Channels Only)'
				GROUP BY Effect,ClientServicesRef,StartDate,Cell) m
		ON m.ClientServicesRef=s.ClientServicesRef AND m.StartDate=s.StartDate AND m.Effect=s.Effect AND m.Cell=s.Cell
		LEFT JOIN (SELECT Effect,ClientServicesRef,StartDate,Cell, 
				AVG(SPC_PooledStdDev) PooledStdDevSPC, AVG(SPC_DegreesOfFreedom) DegreesOfFreedomSPC,
				AVG(RR_PooledStdDev) PooledStdDevRR, AVG(RR_DegreesOfFreedom) DegreesOfFreedomRR, 
				AVG(SPS_PooledStdDev) PooledStdDevSPS, AVG(SPS_DegreesOfFreedom) DegreesOfFreedomSPS 
				FROM (SELECT * FROM Warehouse.MI.CampaignExternalResultsLTE_Workings UNION SELECT * FROM Warehouse.MI.CampaignInternalResultsLTE_Workings) a
				WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level='Bespoke Total'
				AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Main Results (Qualifying MIDs or Channels Only)'
				GROUP BY Effect,ClientServicesRef,StartDate,Cell) mstd
		ON mstd.ClientServicesRef=s.ClientServicesRef AND mstd.StartDate=s.StartDate AND mstd.Effect=s.Effect AND mstd.Cell=s.Cell 
		LEFT JOIN (SELECT Effect,ClientServicesRef,StartDate,Cell, SUM(Sales_M) QualyfingSales, SUM(IncrementalSales) IncrementalQualyfingSales, 
				SUM(Cashback_M) QualyfingCashback
				FROM (SELECT * FROM Warehouse.MI.CampaignExternalResultsLTE_Workings UNION SELECT * FROM Warehouse.MI.CampaignInternalResultsLTE_Workings) a
				WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level='Bespoke Total'
				AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Above Spend Threshold'
				GROUP BY Effect,ClientServicesRef,StartDate,Cell) q
		ON q.ClientServicesRef=s.ClientServicesRef AND q.StartDate=s.StartDate AND q.Effect=s.Effect AND q.Cell=s.Cell
		WHERE s.Cardholders>0
    
			 -- Uplif calculations
			 UPDATE Warehouse.MI.CampaignInternalResultsLTEFinalWave_BespokeCell
			 SET SalesUplift=CASE WHEN IncrementalSales<Sales THEN 1.0*IncrementalSales/(Sales-IncrementalSales) ELSE IncrementalSales END
			   ,RRUplift=CASE WHEN IncrementalSpenders<Spenders THEN 1.0*IncrementalSpenders/(Sales-IncrementalSpenders) ELSE IncrementalSpenders END
			   ,ATVUplift=CASE WHEN IncrementalTransactions<Transactions AND IncrementalSales<Sales AND Transactions>0 THEN (1.0*Sales/Transactions)/(1.0*(Sales-IncrementalSales)/(Transactions-IncrementalTransactions))-1.0 ELSE 0 END
			   ,ATFUplift=CASE WHEN IncrementalSpenders<Spenders AND IncrementalTransactions<Transactions AND Spenders>0 THEN (1.0*Transactions/Spenders)/(1.0*(Transactions-IncrementalTransactions)/(Spenders-IncrementalSpenders))-1.0 ELSE 0 END
			   ,SPS_Diff=CASE WHEN IncrementalSpenders<Spenders AND IncrementalSales<Sales AND Spenders>0 THEN (1.0*Sales/Spenders)-(1.0*(Sales-IncrementalSales)/(Spenders-IncrementalSpenders)) ELSE 0 END
			 WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

			 UPDATE Warehouse.MI.CampaignInternalResultsLTEFinalWave_BespokeCell
			 SET MainDriver=CASE WHEN SalesUplift<=0 THEN 'N/A'
							 WHEN RRUplift>=ATVUplift AND RRUplift>=ATFUplift THEN 'RR'
							 WHEN ATVUplift>=ATFUplift THEN 'ATV' ELSE 'ATF' END
			 WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

			 UPDATE Warehouse.MI.CampaignInternalResultsLTEFinalWave_BespokeCell SET
			 TScoreSPC=CASE WHEN PooledStdDevSPC>0 THEN ABS(1.0*IncrementalSales/Cardholders)/PooledStdDevSPC ELSE 0 END,
			 TScoreRR=CASE WHEN PooledStdDevRR>0 THEN ABS(1.0*IncrementalSpenders/Cardholders)/PooledStdDevRR ELSE 0 END,
			 TScoreSPS=CASE WHEN PooledStdDevSPS>0 THEN ABS(1.0*SPS_Diff)/PooledStdDevSPS ELSE 0 END
			 WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
    
			-- Significance calculations
			 UPDATE Warehouse.MI.CampaignInternalResultsLTEFinalWave_BespokeCell SET
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
			 FROM Warehouse.MI.CampaignInternalResultsLTEFinalWave_BespokeCell w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomSPC
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomSPC) and t.Tailes=2
			 WHERE w.ClientServicesRef=@ClientServicesRef AND w.StartDate=@StartDate
    
			 UPDATE Warehouse.MI.CampaignInternalResultsLTEFinalWave_BespokeCell SET
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
			 FROM Warehouse.MI.CampaignInternalResultsLTEFinalWave_BespokeCell w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomRR
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomRR) and t.Tailes=2
			 WHERE w.ClientServicesRef=@ClientServicesRef AND w.StartDate=@StartDate

			 UPDATE Warehouse.MI.CampaignInternalResultsLTEFinalWave_BespokeCell SET
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
			 FROM Warehouse.MI.CampaignInternalResultsLTEFinalWave_BespokeCell w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomSPS
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomSPS) and t.Tailes=2
			 WHERE w.ClientServicesRef=@ClientServicesRef AND w.StartDate=@StartDate
			 
 		-- Populate CampaignInternalResultsLTEFinalWave_Segment (delete old entries first)   
    		DELETE FROM Warehouse.MI.CampaignInternalResultsLTEFinalWave_Segment
		WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

		INSERT INTO Warehouse.MI.CampaignInternalResultsLTEFinalWave_Segment
		(Effect,ClientServicesRef,StartDate, SegmentID, ControlGroup,
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
		RewardOverride, IncrementalOverride,
		UpliftCardholders_Perc,UpliftCardholders_BelowLimit)
		SELECT DISTINCT s.Effect,s.ClientServicesRef, s.StartDate, s.SegmentID, 
		@ControlGroup,@CustomerUniverse, 'Segment',
		m.ControlGroupSize, s.Cardholders, s.Sales, s.Transactions, s.Spenders,	 
		CASE WHEN UpliftCardholders>=@ExclusionsAbsLimit AND UpliftCardholders>=@ExclusionsPercLimit*Cardholders
			THEN 1.0*Cardholders/UpliftCardholders ELSE 0 END
			*Stratification.least(COALESCE(m.IncrementalSales,0),s.Sales),
		CASE WHEN UpliftCardholders>=@ExclusionsAbsLimit AND UpliftCardholders>=@ExclusionsPercLimit*Cardholders
			THEN 1.0*Cardholders/UpliftCardholders ELSE 0 END
			*Stratification.least(COALESCE(m.IncrementalSales,0),s.Sales)*p.Margin,
		CASE WHEN UpliftCardholders>=@ExclusionsAbsLimit AND UpliftCardholders>=@ExclusionsPercLimit*Cardholders
			THEN 1.0*Cardholders/UpliftCardholders ELSE 0 END
			*Stratification.least(COALESCE(m.IncrementalTransactions,0),s.Transactions),
		CASE WHEN UpliftCardholders>=@ExclusionsAbsLimit AND UpliftCardholders>=@ExclusionsPercLimit*Cardholders
			THEN 1.0*Cardholders/UpliftCardholders ELSE 0 END
			*Stratification.least(COALESCE(m.IncrementalSpenders,0),s.Spenders),
		mstd.PooledStdDevSPC,mstd.DegreesOfFreedomSPC,
		mstd.PooledStdDevRR,mstd.DegreesOfFreedomRR,
		mstd.PooledStdDevSPS,mstd.DegreesOfFreedomSPS,
		COALESCE(q.QualyfingSales,s.Sales),
		s.Cashback,COALESCE(q.QualyfingCashback,s.Cashback),
		s.Commission,m.CampaignCost,
		s.RewardOverride, m.IncrementalOverride,
		1.0*COALESCE(UpliftCardholders,0)/s.Cardholders,
		CASE WHEN UpliftCardholders>=@ExclusionsAbsLimit AND UpliftCardholders>=@ExclusionsPercLimit*Cardholders
			THEN 1 ELSE 0 END UpliftCardholders_BelowLimit
		FROM (SELECT Effect,ClientServicesRef,StartDate,SegmentID, SUM(Cardholders) Cardholders, SUM(Sales) Sales, SUM(Transactions) Transactions, SUM(Spenders) Spenders,
			 SUM(Cashback) Cashback, SUM(Commission) Commission, 
			 SUM(RewardOverride) RewardOverride
			 FROM (SELECT * FROM Warehouse.MI.CampaignExternalResultsLTE_PureSales UNION SELECT * FROM Warehouse.MI.CampaignInternalResultsLTE_PureSales) a
			 WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level='Segment'
			 AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Main Results (Qualifying MIDs or Channels Only)'
			 GROUP BY Effect,ClientServicesRef,StartDate,SegmentID) s
		LEFT JOIN (SELECT ClientServicesRef,StartDate,AVG(Margin) Margin, AVG(r.Override_Pct_of_CBP) OverridePct
				 FROM Warehouse.MI.CampaignDetailsWave_PartnerLookup w
				 INNER JOIN Warehouse.Relational.Master_Retailer_Table r ON r.PartnerID=w.PartnerID
				 GROUP BY ClientServicesRef,StartDate) p
		ON p.ClientServicesRef=s.ClientServicesRef AND p.StartDate=s.StartDate 
		LEFT JOIN (SELECT Effect,ClientServicesRef,StartDate,SegmentID, SUM(Cardholders_M) UpliftCardholders, SUM(Cardholders_C) ControlGroupSize, SUM(IncrementalSales) IncrementalSales, 
				SUM(IncrementalTransactions) IncrementalTransactions, SUM(IncrementalSpenders) IncrementalSpenders,
				SUM(ExtraCommissionGenerated) CampaignCost,SUM(ExtraOverrideGenerated) IncrementalOverride -- Extra on the top of base offer
				FROM (SELECT * FROM Warehouse.MI.CampaignExternalResultsLTE_Workings UNION SELECT * FROM Warehouse.MI.CampaignInternalResultsLTE_Workings) a
				WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level='Segment'
				AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Main Results (Qualifying MIDs or Channels Only)'
				GROUP BY Effect,ClientServicesRef,StartDate,SegmentID) m
		ON m.ClientServicesRef=s.ClientServicesRef AND m.StartDate=s.StartDate AND m.Effect=s.Effect AND m.SegmentID=s.SegmentID
		LEFT JOIN (SELECT Effect,ClientServicesRef,StartDate,SegmentID, 
				AVG(SPC_PooledStdDev) PooledStdDevSPC, AVG(SPC_DegreesOfFreedom) DegreesOfFreedomSPC,
				AVG(RR_PooledStdDev) PooledStdDevRR, AVG(RR_DegreesOfFreedom) DegreesOfFreedomRR, 
				AVG(SPS_PooledStdDev) PooledStdDevSPS, AVG(SPS_DegreesOfFreedom) DegreesOfFreedomSPS 
				FROM (SELECT * FROM Warehouse.MI.CampaignExternalResultsLTE_Workings UNION SELECT * FROM Warehouse.MI.CampaignInternalResultsLTE_Workings) a
				WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level='Segment'
				AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Main Results (Qualifying MIDs or Channels Only)'
				GROUP BY Effect,ClientServicesRef,StartDate,SegmentID) mstd
		ON mstd.ClientServicesRef=s.ClientServicesRef AND mstd.StartDate=s.StartDate AND mstd.Effect=s.Effect AND mstd.SegmentID=s.SegmentID    
		LEFT JOIN (SELECT Effect,ClientServicesRef,StartDate,SegmentID, SUM(Sales_M) QualyfingSales, SUM(IncrementalSales) IncrementalQualyfingSales, 
				SUM(Cashback_M) QualyfingCashback
				FROM (SELECT * FROM Warehouse.MI.CampaignExternalResultsLTE_Workings UNION SELECT * FROM Warehouse.MI.CampaignInternalResultsLTE_Workings) a
				WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level='Segment'
				AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Above Spend Threshold'
				GROUP BY Effect,ClientServicesRef,StartDate,SegmentID) q
		ON q.ClientServicesRef=s.ClientServicesRef AND q.StartDate=s.StartDate AND q.Effect=s.Effect AND q.SegmentID=s.SegmentID
		WHERE s.Cardholders>0
    
			 -- Uplif calculations
			 UPDATE Warehouse.MI.CampaignInternalResultsLTEFinalWave_Segment
			 SET SalesUplift=CASE WHEN IncrementalSales<Sales THEN 1.0*IncrementalSales/(Sales-IncrementalSales) ELSE IncrementalSales END
			   ,RRUplift=CASE WHEN IncrementalSpenders<Spenders THEN 1.0*IncrementalSpenders/(Sales-IncrementalSpenders) ELSE IncrementalSpenders END
			   ,ATVUplift=CASE WHEN IncrementalTransactions<Transactions AND IncrementalSales<Sales AND Transactions>0 THEN (1.0*Sales/Transactions)/(1.0*(Sales-IncrementalSales)/(Transactions-IncrementalTransactions))-1.0 ELSE 0 END
			   ,ATFUplift=CASE WHEN IncrementalSpenders<Spenders AND IncrementalTransactions<Transactions AND Spenders>0 THEN (1.0*Transactions/Spenders)/(1.0*(Transactions-IncrementalTransactions)/(Spenders-IncrementalSpenders))-1.0 ELSE 0 END
			   ,SPS_Diff=CASE WHEN IncrementalSpenders<Spenders AND IncrementalSales<Sales AND Spenders>0 THEN (1.0*Sales/Spenders)-(1.0*(Sales-IncrementalSales)/(Spenders-IncrementalSpenders)) ELSE 0 END
			 WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

			 UPDATE Warehouse.MI.CampaignInternalResultsLTEFinalWave_Segment
			 SET MainDriver=CASE WHEN SalesUplift<=0 THEN 'N/A'
							 WHEN RRUplift>=ATVUplift AND RRUplift>=ATFUplift THEN 'RR'
							 WHEN ATVUplift>=ATFUplift THEN 'ATV' ELSE 'ATF' END
			 WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

			 UPDATE Warehouse.MI.CampaignInternalResultsLTEFinalWave_Segment SET
			 TScoreSPC=CASE WHEN PooledStdDevSPC>0 THEN ABS(1.0*IncrementalSales/Cardholders)/PooledStdDevSPC ELSE 0 END,
			 TScoreRR=CASE WHEN PooledStdDevRR>0 THEN ABS(1.0*IncrementalSpenders/Cardholders)/PooledStdDevRR ELSE 0 END,
			 TScoreSPS=CASE WHEN PooledStdDevSPS>0 THEN ABS(1.0*SPS_Diff)/PooledStdDevSPS ELSE 0 END
			 WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
    
			-- Significance calculations
			 UPDATE Warehouse.MI.CampaignInternalResultsLTEFinalWave_Segment SET
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
			 FROM Warehouse.MI.CampaignInternalResultsLTEFinalWave_Segment w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomSPC
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomSPC) and t.Tailes=2
			 WHERE w.ClientServicesRef=@ClientServicesRef AND w.StartDate=@StartDate
    
			 UPDATE Warehouse.MI.CampaignInternalResultsLTEFinalWave_Segment SET
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
			 FROM Warehouse.MI.CampaignInternalResultsLTEFinalWave_Segment w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomRR
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomRR) and t.Tailes=2
			 WHERE w.ClientServicesRef=@ClientServicesRef AND w.StartDate=@StartDate

			 UPDATE Warehouse.MI.CampaignInternalResultsLTEFinalWave_Segment SET
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
			 FROM Warehouse.MI.CampaignInternalResultsLTEFinalWave_Segment w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomSPS
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomSPS) and t.Tailes=2
			 WHERE w.ClientServicesRef=@ClientServicesRef AND w.StartDate=@StartDate

 		-- Populate CampaignInternalResultsLTEFinalWave_SuperSegment (delete old entries first)   
    		DELETE FROM Warehouse.MI.CampaignInternalResultsLTEFinalWave_SuperSegment
		WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

		INSERT INTO Warehouse.MI.CampaignInternalResultsLTEFinalWave_SuperSegment
		(Effect,ClientServicesRef,StartDate, SegmentID, ControlGroup,
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
		RewardOverride, IncrementalOverride,
		UpliftCardholders_Perc,UpliftCardholders_BelowLimit)
		SELECT DISTINCT s.Effect,s.ClientServicesRef, s.StartDate, s.SegmentID, 
		@ControlGroup,@CustomerUniverse, 'SuperSegment',
		m.ControlGroupSize, s.Cardholders, s.Sales, s.Transactions, s.Spenders,	 
		CASE WHEN UpliftCardholders>=@ExclusionsAbsLimit AND UpliftCardholders>=@ExclusionsPercLimit*Cardholders
			THEN 1.0*Cardholders/UpliftCardholders ELSE 0 END
			*Stratification.least(COALESCE(m.IncrementalSales,0),s.Sales),
		CASE WHEN UpliftCardholders>=@ExclusionsAbsLimit AND UpliftCardholders>=@ExclusionsPercLimit*Cardholders
			THEN 1.0*Cardholders/UpliftCardholders ELSE 0 END
			*Stratification.least(COALESCE(m.IncrementalSales,0),s.Sales)*p.Margin,
		CASE WHEN UpliftCardholders>=@ExclusionsAbsLimit AND UpliftCardholders>=@ExclusionsPercLimit*Cardholders
			THEN 1.0*Cardholders/UpliftCardholders ELSE 0 END
			*Stratification.least(COALESCE(m.IncrementalTransactions,0),s.Transactions),
		CASE WHEN UpliftCardholders>=@ExclusionsAbsLimit AND UpliftCardholders>=@ExclusionsPercLimit*Cardholders
			THEN 1.0*Cardholders/UpliftCardholders ELSE 0 END
			*Stratification.least(COALESCE(m.IncrementalSpenders,0),s.Spenders),
		mstd.PooledStdDevSPC,mstd.DegreesOfFreedomSPC,
		mstd.PooledStdDevRR,mstd.DegreesOfFreedomRR,
		mstd.PooledStdDevSPS,mstd.DegreesOfFreedomSPS,
		COALESCE(q.QualyfingSales,s.Sales),
		s.Cashback,COALESCE(q.QualyfingCashback,s.Cashback),
		s.Commission,m.CampaignCost,
		s.RewardOverride, m.IncrementalOverride,
		1.0*COALESCE(UpliftCardholders,0)/s.Cardholders,
		CASE WHEN UpliftCardholders>=@ExclusionsAbsLimit AND UpliftCardholders>=@ExclusionsPercLimit*Cardholders
			THEN 1 ELSE 0 END UpliftCardholders_BelowLimit
		FROM (SELECT Effect,ClientServicesRef,StartDate,SegmentID, SUM(Cardholders) Cardholders, SUM(Sales) Sales, SUM(Transactions) Transactions, SUM(Spenders) Spenders,
			 SUM(Cashback) Cashback, SUM(Commission) Commission, 
			 SUM(RewardOverride) RewardOverride
			 FROM (SELECT * FROM Warehouse.MI.CampaignExternalResultsLTE_PureSales UNION SELECT * FROM Warehouse.MI.CampaignInternalResultsLTE_PureSales) a
			 WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level='SuperSegment'
			 AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Main Results (Qualifying MIDs or Channels Only)'
			 GROUP BY Effect,ClientServicesRef,StartDate,SegmentID) s
		LEFT JOIN (SELECT ClientServicesRef,StartDate,AVG(Margin) Margin, AVG(r.Override_Pct_of_CBP) OverridePct
				 FROM Warehouse.MI.CampaignDetailsWave_PartnerLookup w
				 INNER JOIN Warehouse.Relational.Master_Retailer_Table r ON r.PartnerID=w.PartnerID
				 GROUP BY ClientServicesRef,StartDate) p
		ON p.ClientServicesRef=s.ClientServicesRef AND p.StartDate=s.StartDate
		LEFT JOIN (SELECT Effect,ClientServicesRef,StartDate,SegmentID, SUM(Cardholders_M) UpliftCardholders, SUM(Cardholders_C) ControlGroupSize, SUM(IncrementalSales) IncrementalSales, 
				SUM(IncrementalTransactions) IncrementalTransactions, SUM(IncrementalSpenders) IncrementalSpenders,
				SUM(ExtraCommissionGenerated) CampaignCost,SUM(ExtraOverrideGenerated) IncrementalOverride -- Extra on the top of base offer
				FROM (SELECT * FROM Warehouse.MI.CampaignExternalResultsLTE_Workings UNION SELECT * FROM Warehouse.MI.CampaignInternalResultsLTE_Workings) a
				WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level='SuperSegment'
				AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Main Results (Qualifying MIDs or Channels Only)'
				GROUP BY Effect,ClientServicesRef,StartDate,SegmentID) m
		ON m.ClientServicesRef=s.ClientServicesRef AND m.StartDate=s.StartDate AND m.Effect=s.Effect AND m.SegmentID=s.SegmentID
		LEFT JOIN (SELECT Effect,ClientServicesRef,StartDate,SegmentID, 
				AVG(SPC_PooledStdDev) PooledStdDevSPC, AVG(SPC_DegreesOfFreedom) DegreesOfFreedomSPC,
				AVG(RR_PooledStdDev) PooledStdDevRR, AVG(RR_DegreesOfFreedom) DegreesOfFreedomRR, 
				AVG(SPS_PooledStdDev) PooledStdDevSPS, AVG(SPS_DegreesOfFreedom) DegreesOfFreedomSPS 
				FROM (SELECT * FROM Warehouse.MI.CampaignExternalResultsLTE_Workings UNION SELECT * FROM Warehouse.MI.CampaignInternalResultsLTE_Workings) a
				WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level='SuperSegment'
				AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Main Results (Qualifying MIDs or Channels Only)'
				GROUP BY Effect,ClientServicesRef,StartDate,SegmentID) mstd
		ON mstd.ClientServicesRef=s.ClientServicesRef AND mstd.StartDate=s.StartDate AND mstd.Effect=s.Effect AND mstd.SegmentID=s.SegmentID 
		LEFT JOIN (SELECT Effect,ClientServicesRef,StartDate,SegmentID, SUM(Sales_M) QualyfingSales, SUM(IncrementalSales) IncrementalQualyfingSales, 
				SUM(Cashback_M) QualyfingCashback
				FROM (SELECT * FROM Warehouse.MI.CampaignExternalResultsLTE_Workings UNION SELECT * FROM Warehouse.MI.CampaignInternalResultsLTE_Workings) a
				WHERE ControlGroup=@ControlGroup AND CustomerUniverse=@CustomerUniverse AND Level='SuperSegment'
				AND ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate AND SalesType='Above Spend Threshold'
				GROUP BY Effect,ClientServicesRef,StartDate,SegmentID) q
		ON q.ClientServicesRef=s.ClientServicesRef AND q.StartDate=s.StartDate AND q.Effect=s.Effect AND q.SegmentID=s.SegmentID
		WHERE s.Cardholders>0
    
			 -- Uplif calculations
			 UPDATE Warehouse.MI.CampaignInternalResultsLTEFinalWave_SuperSegment
			 SET SalesUplift=CASE WHEN IncrementalSales<Sales THEN 1.0*IncrementalSales/(Sales-IncrementalSales) ELSE IncrementalSales END
			   ,RRUplift=CASE WHEN IncrementalSpenders<Spenders THEN 1.0*IncrementalSpenders/(Sales-IncrementalSpenders) ELSE IncrementalSpenders END
			   ,ATVUplift=CASE WHEN IncrementalTransactions<Transactions AND IncrementalSales<Sales AND Transactions>0 THEN (1.0*Sales/Transactions)/(1.0*(Sales-IncrementalSales)/(Transactions-IncrementalTransactions))-1.0 ELSE 0 END
			   ,ATFUplift=CASE WHEN IncrementalSpenders<Spenders AND IncrementalTransactions<Transactions AND Spenders>0 THEN (1.0*Transactions/Spenders)/(1.0*(Transactions-IncrementalTransactions)/(Spenders-IncrementalSpenders))-1.0 ELSE 0 END
			   ,SPS_Diff=CASE WHEN IncrementalSpenders<Spenders AND IncrementalSales<Sales AND Spenders>0 THEN (1.0*Sales/Spenders)-(1.0*(Sales-IncrementalSales)/(Spenders-IncrementalSpenders)) ELSE 0 END
			 WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

			 UPDATE Warehouse.MI.CampaignInternalResultsLTEFinalWave_SuperSegment
			 SET MainDriver=CASE WHEN SalesUplift<=0 THEN 'N/A'
							 WHEN RRUplift>=ATVUplift AND RRUplift>=ATFUplift THEN 'RR'
							 WHEN ATVUplift>=ATFUplift THEN 'ATV' ELSE 'ATF' END
			 WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

			 UPDATE Warehouse.MI.CampaignInternalResultsLTEFinalWave_SuperSegment SET
			 TScoreSPC=CASE WHEN PooledStdDevSPC>0 THEN ABS(1.0*IncrementalSales/Cardholders)/PooledStdDevSPC ELSE 0 END,
			 TScoreRR=CASE WHEN PooledStdDevRR>0 THEN ABS(1.0*IncrementalSpenders/Cardholders)/PooledStdDevRR ELSE 0 END,
			 TScoreSPS=CASE WHEN PooledStdDevSPS>0 THEN ABS(1.0*SPS_Diff)/PooledStdDevSPS ELSE 0 END
			 WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate
    
			-- Significance calculations
			 UPDATE Warehouse.MI.CampaignInternalResultsLTEFinalWave_SuperSegment SET
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
			 FROM Warehouse.MI.CampaignInternalResultsLTEFinalWave_SuperSegment w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomSPC
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomSPC) and t.Tailes=2
			 WHERE w.ClientServicesRef=@ClientServicesRef AND w.StartDate=@StartDate
    
			 UPDATE Warehouse.MI.CampaignInternalResultsLTEFinalWave_SuperSegment SET
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
			 FROM Warehouse.MI.CampaignInternalResultsLTEFinalWave_SuperSegment w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomRR
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomRR) and t.Tailes=2
			 WHERE w.ClientServicesRef=@ClientServicesRef AND w.StartDate=@StartDate

			 UPDATE Warehouse.MI.CampaignInternalResultsLTEFinalWave_SuperSegment SET
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
			 FROM Warehouse.MI.CampaignInternalResultsLTEFinalWave_SuperSegment w
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
Run Store Procedure MI.CampaignInternalResultsLTE_Calculate first.' 

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