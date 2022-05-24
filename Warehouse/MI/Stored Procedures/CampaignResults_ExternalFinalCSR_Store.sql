-- =============================================
-- Author:		Dorota
-- Create date:	15/05/2015
-- =============================================

CREATE PROCEDURE MI.CampaignResults_ExternalFinalCSR_Store AS -- unhide this row to modify SP

BEGIN 

    -- Log when Store Procedure started running in CamapainResults_Log
    INSERT INTO Warehouse.MI.Campaign_Log
    (StoreProcedureName,  
    RunByUser , RunStartTime)
    SELECT 'CampaignResults_ExternalFinalCSR_Store', 
    SYSTEM_USER, GETDATE()

    -- Store RowID for curently running Store Procedure
    DECLARE @MY_ID AS INT;
    SET @MY_ID= (SELECT SCOPE_IDENTITY());

    -- List of all Campaigns (ClientServicesRef) that can be stored in CampaignExternalResultsFinalCSR Tables (all the Waves were measured)
    IF OBJECT_ID('tempdb..#Waves_Measured') IS NOT NULL DROP TABLE #Waves_Measured
    SELECT  d.ClientServicesRef, COUNT(DISTINCT d.StartDate) WavesLive,
    COUNT(DISTINCT rf.StartDate) WavesMeasured, 
    CASE WHEN COUNT(DISTINCT ControlGroup)>1 THEN 'Various' ELSE MAX(ControlGroup) END ControlGroup,
    CASE WHEN COUNT(DISTINCT CustomerUniverse)>1 THEN 'Various' ELSE MAX(CustomerUniverse) END CustomerUniverse,
    CASE WHEN COUNT(DISTINCT AggregationLevel)>1 THEN 'Various' ELSE MAX(AggregationLevel) END AggregationLevel,
    MAX(rf.Inserted) Inserted
    INTO #Waves_Measured
    FROM Warehouse.MI.CampaignDetailsWave d
    LEFT JOIN Warehouse.MI.CampaignExternalResultsFinalWave rf 
    ON rf.ClientServicesRef=d.ClientServicesRef AND rf.StartDate=d.StartDate
    GROUP BY d.ClientServicesRef
    HAVING COUNT(DISTINCT d.StartDate)=COUNT(DISTINCT rf.StartDate)

    -- Check if Results for uncompleted camapign are stored in CampaignExternalResultsFinalCSR, if yes delete them
    DELETE FROM csr
    FROM Warehouse.MI.CampaignExternalResultsFinalCSR  csr
    WHERE csr.ClientServicesRef NOT IN 
	   (SELECT ClientServicesRef FROM #Waves_Measured)

    -- Check if Results are already stored in CSR tables and if Wave results were modified afterwards, if yes delete them
    DELETE FROM csr
    FROM Warehouse.MI.CampaignExternalResultsFinalCSR csr
    INNER JOIN #Waves_Measured wm ON wm.ClientServicesRef=csr.ClientServicesRef
    AND wm.Inserted>csr.Inserted -- Wave results modified, so CSR table needs to be updated accordingly

    -- Insert new results on CSR level as a sum of Wave results
    INSERT INTO Warehouse.MI.CampaignExternalResultsFinalCSR 
    (ClientServicesRef,
    ControlGroup,CustomerUniverse,AggregationLevel,
    ControlGroupSize,Cardholders,Sales,Transactions,Spenders,
    IncrementalSales,IncrementalMargin,IncrementalTransactions,IncrementalSpenders,
    PooledStdDevSPC, DegreesOfFreedomSPC,
    PooledStdDevRR,DegreesOfFreedomRR,
    PooledStdDevSPS,DegreesOfFreedomSPS,
    QualyfingSales,Cashback,QualyfingCashback,
    Commission,CampaignCost,RewardOverride,IncrementalOverride)
    SELECT DISTINCT wm.ClientServicesRef, 
    wm.ControlGroup,wm.CustomerUniverse,wm.AggregationLevel,
    SUM(rf.ControlGroupSize), SUM(rf.Cardholders),SUM(rf.Sales),SUM(rf.Transactions),SUM(rf.Spenders),
    SUM(rf.IncrementalSales),SUM(rf.IncrementalMargin),SUM(rf.IncrementalTransactions),SUM(rf.IncrementalSpenders),
    -- Assuming that Variance for SUM of Sales/Spenders/SPS is Average weigthed by number of Cardholders (or Spenders for SPS), and DF are just sum of DF
    -- It not 100% accurate (tends to underestimate) but the best estimate I could came up with without having to recalculate the variance
    SQRT(SUM(POWER(rf.PooledStdDevSPC,2)*1.0*rf.Cardholders)/SUM(rf.Cardholders)), SUM(rf.DegreesOfFreedomSPC),
    SQRT(SUM(POWER(rf.PooledStdDevRR,2)*1.0*rf.Cardholders)/SUM(rf.Cardholders)),SUM(rf.DegreesOfFreedomRR),
    CASE WHEN SUM(rf.Spenders)>0 THEN SQRT(SUM(POWER(rf.PooledStdDevRR,2)*1.0*rf.Spenders)/SUM(rf.Spenders)) ELSE 0 END,SUM(rf.DegreesOfFreedomSPS),
    SUM(rf.QualyfingSales),SUM(rf.Cashback),SUM(rf.QualyfingCashback),
    SUM(rf.Commission),SUM(rf.CampaignCost),SUM(rf.RewardOverride),SUM(rf.IncrementalOverride)
    FROM #Waves_Measured wm
    INNER JOIN Warehouse.MI.CampaignExternalResultsFinalWave rf  ON rf.ClientServicesRef=wm.ClientServicesRef
    WHERE NOT EXISTS (SELECT 1 FROM Warehouse.MI.CampaignExternalResultsFinalCSR old 
    WHERE old.ClientServicesRef=wm.ClientServicesRef)
    GROUP BY wm.ClientServicesRef, 
    wm.ControlGroup,wm.CustomerUniverse,wm.AggregationLevel

    			 -- Uplif calculations
			 UPDATE Warehouse.MI.CampaignExternalResultsFinalCSR
			 SET SalesUplift=CASE WHEN IncrementalSales<Sales THEN 1.0*IncrementalSales/(Sales-IncrementalSales) ELSE IncrementalSales END
			   ,RRUplift=CASE WHEN IncrementalSpenders<Spenders THEN 1.0*IncrementalSpenders/(Sales-IncrementalSpenders) ELSE IncrementalSpenders END
			   ,ATVUplift=CASE WHEN IncrementalTransactions<Transactions AND IncrementalSales<Sales AND Transactions>0 THEN (1.0*Sales/Transactions)/(1.0*(Sales-IncrementalSales)/(Transactions-IncrementalTransactions))-1.0 ELSE 0 END
			   ,ATFUplift=CASE WHEN IncrementalSpenders<Spenders AND IncrementalTransactions<Transactions AND Spenders>0 THEN (1.0*Transactions/Spenders)/(1.0*(Transactions-IncrementalTransactions)/(Spenders-IncrementalSpenders))-1.0 ELSE 0 END
			   ,SPS_Diff=CASE WHEN IncrementalSpenders<Spenders AND IncrementalSales<Sales AND Spenders>0 THEN (1.0*Sales/Spenders)-(1.0*(Sales-IncrementalSales)/(Spenders-IncrementalSpenders)) ELSE 0 END
			 WHERE SalesUplift IS NULL

			 UPDATE Warehouse.MI.CampaignExternalResultsFinalCSR
			 SET MainDriver=CASE WHEN SalesUplift<=0 THEN 'N/A'
							 WHEN RRUplift>=ATVUplift AND RRUplift>=ATFUplift THEN 'RR'
							 WHEN ATVUplift>=ATFUplift THEN 'ATV' ELSE 'ATF' END
			 WHERE MainDriver IS NULL

			 UPDATE Warehouse.MI.CampaignExternalResultsFinalCSR SET
			 TScoreSPC=CASE WHEN PooledStdDevSPC>0 THEN ABS(1.0*IncrementalSales/Cardholders)/PooledStdDevSPC ELSE 0 END,
			 TScoreRR=CASE WHEN PooledStdDevRR>0 THEN ABS(1.0*IncrementalSpenders/Cardholders)/PooledStdDevRR ELSE 0 END,
			 TScoreSPS=CASE WHEN PooledStdDevSPS>0 THEN ABS(1.0*SPS_Diff)/PooledStdDevSPS ELSE 0 END
			 WHERE TScoreSPC IS NULL
    
			-- Significance calculations
			 UPDATE Warehouse.MI.CampaignExternalResultsFinalCSR SET
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
			 FROM Warehouse.MI.CampaignExternalResultsFinalCSR w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomSPC
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomSPC) and t.Tailes=2
			 WHERE PValueSPC IS NULL
    
			 UPDATE Warehouse.MI.CampaignExternalResultsFinalCSR SET
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
			 FROM Warehouse.MI.CampaignExternalResultsFinalCSR w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomRR
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomRR) and t.Tailes=2
			 WHERE PValueRR IS NULL

			 UPDATE Warehouse.MI.CampaignExternalResultsFinalCSR SET
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
			 FROM Warehouse.MI.CampaignExternalResultsFinalCSR w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomSPS
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomSPS) and t.Tailes=2
			 WHERE PValueSPS IS NULL
			 
    -- List of all Campaigns (ClientServicesRef) that can be stored in CampaignExternalResultsFinalCSR_BespokeCell Tables (all the Waves were measured)
    IF OBJECT_ID('tempdb..#Waves_Measured_BespokeCell') IS NOT NULL DROP TABLE #Waves_Measured_BespokeCell
    SELECT d.ClientServicesRef, COUNT(DISTINCT CONCAT(d.StartDate,d.Cell)) WavesLive,
    COUNT(DISTINCT CONCAT(rf.StartDate,rf.Cell)) WavesMeasured, 
    CASE WHEN COUNT(DISTINCT ControlGroup)>1 THEN 'Various' ELSE MAX(ControlGroup) END ControlGroup,
    CASE WHEN COUNT(DISTINCT CustomerUniverse)>1 THEN 'Various' ELSE MAX(CustomerUniverse) END CustomerUniverse,
    CASE WHEN COUNT(DISTINCT Level)>1 THEN 'Various' ELSE MAX(Level) END Level,
    MAX(rf.Inserted) Inserted
    INTO #Waves_Measured_BespokeCell
    FROM Warehouse.MI.CampaignDetailsWave_BespokeCell d
    LEFT JOIN Warehouse.MI.CampaignExternalResultsFinalWave_BespokeCell rf 
    ON rf.ClientServicesRef=d.ClientServicesRef AND rf.StartDate=d.StartDate AND rf.Cell=d.Cell
    GROUP BY d.ClientServicesRef
    HAVING COUNT(DISTINCT d.StartDate)=COUNT(DISTINCT rf.StartDate)

    INSERT INTO #Waves_Measured_BespokeCell
    SELECT * FROM #Waves_Measured m
    WHERE m.ClientServicesRef NOT IN (SELECT ClientServicesRef FROM #Waves_Measured_BespokeCell)

    -- Check if Results for uncompleted camapign are stored in CampaignExternalResultsFinalCSR, if yes delete them
    DELETE FROM csr
    FROM Warehouse.MI.CampaignDetailsCSR_BespokeCell csr
    WHERE csr.ClientServicesRef NOT IN 
	   (SELECT ClientServicesRef FROM #Waves_Measured_BespokeCell)

    -- Check if Results are already stored in CSR tables and if Wave results were modified afterwards, if yes delete them
    DELETE FROM csr
    FROM Warehouse.MI.CampaignDetailsCSR_BespokeCell csr
    INNER JOIN #Waves_Measured_BespokeCell wm ON wm.ClientServicesRef=csr.ClientServicesRef
    AND wm.Inserted>csr.Inserted -- Wave results modified, so CSR table needs to be updated accordingly

    -- Insert new results on CSR level as a sum of Wave results
    INSERT INTO Warehouse.MI.CampaignExternalResultsFinalCSR_BespokeCell 
    (ClientServicesRef,Cell,
    ControlGroup,CustomerUniverse,Level,
    ControlGroupSize,Cardholders,Sales,Transactions,Spenders,
    IncrementalSales,IncrementalMargin,IncrementalTransactions,IncrementalSpenders,
    PooledStdDevSPC, DegreesOfFreedomSPC,
    PooledStdDevRR,DegreesOfFreedomRR,
    PooledStdDevSPS,DegreesOfFreedomSPS,
    QualyfingSales,Cashback,QualyfingCashback,
    Commission,CampaignCost,RewardOverride,IncrementalOverride)
    SELECT DISTINCT wm.ClientServicesRef, rf.Cell,
    wm.ControlGroup,wm.CustomerUniverse,wm.Level,
    SUM(rf.ControlGroupSize), SUM(rf.Cardholders),SUM(rf.Sales),SUM(rf.Transactions),SUM(rf.Spenders),
    SUM(rf.IncrementalSales),SUM(rf.IncrementalMargin),SUM(rf.IncrementalTransactions),SUM(rf.IncrementalSpenders),
    -- Assuming that Variance for SUM of Sales/Spenders/SPS is Average weigthed by number of Cardholders (or Spenders for SPS), and DF are just sum of DF
    -- It not 100% accurate (tends to underestimate) but the best estimate I could came up with without having to recalculate the variance
    SQRT(SUM(POWER(rf.PooledStdDevSPC,2)*1.0*rf.Cardholders)/SUM(rf.Cardholders)), SUM(rf.DegreesOfFreedomSPC),
    SQRT(SUM(POWER(rf.PooledStdDevRR,2)*1.0*rf.Cardholders)/SUM(rf.Cardholders)),SUM(rf.DegreesOfFreedomRR),
    CASE WHEN SUM(rf.Spenders)>0 THEN SQRT(SUM(POWER(rf.PooledStdDevRR,2)*1.0*rf.Spenders)/SUM(rf.Spenders)) ELSE 0 END,SUM(rf.DegreesOfFreedomSPS),
    SUM(rf.QualyfingSales),SUM(rf.Cashback),SUM(rf.QualyfingCashback),
    SUM(rf.Commission),SUM(rf.CampaignCost),SUM(rf.RewardOverride),SUM(rf.IncrementalOverride)
    FROM #Waves_Measured_BespokeCell wm
    INNER JOIN Warehouse.MI.CampaignExternalResultsFinalWave_BespokeCell rf  ON rf.ClientServicesRef=wm.ClientServicesRef
    WHERE NOT EXISTS (SELECT 1 FROM Warehouse.MI.CampaignExternalResultsFinalCSR_BespokeCell old 
    WHERE old.ClientServicesRef=wm.ClientServicesRef AND old.Cell=rf.Cell)
    GROUP BY wm.ClientServicesRef, rf.Cell,
    wm.ControlGroup,wm.CustomerUniverse,wm.Level

    			 -- Uplif calculations
			 UPDATE Warehouse.MI.CampaignExternalResultsFinalCSR_BespokeCell
			 SET SalesUplift=CASE WHEN IncrementalSales<Sales THEN 1.0*IncrementalSales/(Sales-IncrementalSales) ELSE IncrementalSales END
			   ,RRUplift=CASE WHEN IncrementalSpenders<Spenders THEN 1.0*IncrementalSpenders/(Sales-IncrementalSpenders) ELSE IncrementalSpenders END
			   ,ATVUplift=CASE WHEN IncrementalTransactions<Transactions AND IncrementalSales<Sales AND Transactions>0 THEN (1.0*Sales/Transactions)/(1.0*(Sales-IncrementalSales)/(Transactions-IncrementalTransactions))-1.0 ELSE 0 END
			   ,ATFUplift=CASE WHEN IncrementalSpenders<Spenders AND IncrementalTransactions<Transactions AND Spenders>0 THEN (1.0*Transactions/Spenders)/(1.0*(Transactions-IncrementalTransactions)/(Spenders-IncrementalSpenders))-1.0 ELSE 0 END
			   ,SPS_Diff=CASE WHEN IncrementalSpenders<Spenders AND IncrementalSales<Sales AND Spenders>0 THEN (1.0*Sales/Spenders)-(1.0*(Sales-IncrementalSales)/(Spenders-IncrementalSpenders)) ELSE 0 END
			 WHERE SalesUplift IS NULL

			 UPDATE Warehouse.MI.CampaignExternalResultsFinalCSR_BespokeCell
			 SET MainDriver=CASE WHEN SalesUplift<=0 THEN 'N/A'
							 WHEN RRUplift>=ATVUplift AND RRUplift>=ATFUplift THEN 'RR'
							 WHEN ATVUplift>=ATFUplift THEN 'ATV' ELSE 'ATF' END
			 WHERE MainDriver IS NULL

			 UPDATE Warehouse.MI.CampaignExternalResultsFinalCSR_BespokeCell SET
			 TScoreSPC=CASE WHEN PooledStdDevSPC>0 THEN ABS(1.0*IncrementalSales/Cardholders)/PooledStdDevSPC ELSE 0 END,
			 TScoreRR=CASE WHEN PooledStdDevRR>0 THEN ABS(1.0*IncrementalSpenders/Cardholders)/PooledStdDevRR ELSE 0 END,
			 TScoreSPS=CASE WHEN PooledStdDevSPS>0 THEN ABS(1.0*SPS_Diff)/PooledStdDevSPS ELSE 0 END
			 WHERE TScoreSPC IS NULL
    
			-- Significance calculations
			 UPDATE Warehouse.MI.CampaignExternalResultsFinalCSR_BespokeCell SET
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
			 FROM Warehouse.MI.CampaignExternalResultsFinalCSR_BespokeCell w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomSPC
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomSPC) and t.Tailes=2
			 WHERE PValueSPC IS NULL
    
			 UPDATE Warehouse.MI.CampaignExternalResultsFinalCSR_BespokeCell SET
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
			 FROM Warehouse.MI.CampaignExternalResultsFinalCSR_BespokeCell w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomRR
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomRR) and t.Tailes=2
			 WHERE PValueRR IS NULL

			 UPDATE Warehouse.MI.CampaignExternalResultsFinalCSR_BespokeCell SET
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
			 FROM Warehouse.MI.CampaignExternalResultsFinalCSR_BespokeCell w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomSPS
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomSPS) and t.Tailes=2
			 WHERE PValueSPS IS NULL

    -- List of all Campaigns (ClientServicesRef) that can be stored in CampaignExternalResultsFinalCSR_Segment Tables (all the Waves were measured)
    IF OBJECT_ID('tempdb..#Waves_Measured_Segment') IS NOT NULL DROP TABLE #Waves_Measured_Segment
    SELECT  d.ClientServicesRef, COUNT(DISTINCT CONCAT(d.StartDate,d.SegmentID)) WavesLive,
    COUNT(DISTINCT CONCAT(rf.StartDate,rf.SegmentID)) WavesMeasured, 
    CASE WHEN COUNT(DISTINCT ControlGroup)>1 THEN 'Various' ELSE MAX(ControlGroup) END ControlGroup,
    CASE WHEN COUNT(DISTINCT CustomerUniverse)>1 THEN 'Various' ELSE MAX(CustomerUniverse) END CustomerUniverse,
    CASE WHEN COUNT(DISTINCT Level)>1 THEN 'Various' ELSE MAX(Level) END Level,
    MAX(rf.Inserted) Inserted
    INTO #Waves_Measured_Segment
    FROM Warehouse.MI.CampaignDetailsWave_Segment d
    LEFT JOIN Warehouse.MI.CampaignExternalResultsFinalWave_Segment rf 
    ON rf.ClientServicesRef=d.ClientServicesRef AND rf.StartDate=d.StartDate AND rf.SegmentID=d.SegmentID
    GROUP BY d.ClientServicesRef
    HAVING COUNT(DISTINCT d.StartDate)=COUNT(DISTINCT rf.StartDate)

    INSERT INTO #Waves_Measured_Segment
    SELECT * FROM #Waves_Measured m
    WHERE m.ClientServicesRef NOT IN (SELECT ClientServicesRef FROM #Waves_Measured_Segment)

    -- Check if Results for uncompleted camapign are stored in CampaignExternalResultsFinalCSR, if yes delete them
    DELETE FROM csr
    FROM Warehouse.MI.CampaignDetailsCSR_Segment csr
    WHERE csr.ClientServicesRef NOT IN 
	   (SELECT ClientServicesRef FROM #Waves_Measured_Segment)

    -- Check if Results are already stored in CSR tables and if Wave results were modified afterwards, if yes delete them
    DELETE FROM csr
    FROM Warehouse.MI.CampaignDetailsCSR_Segment csr
    INNER JOIN #Waves_Measured_Segment wm ON wm.ClientServicesRef=csr.ClientServicesRef
    AND wm.Inserted>csr.Inserted -- Wave results modified, so CSR table needs to be updated accordingly

    -- Insert new results on CSR level as a sum of Wave results
    INSERT INTO Warehouse.MI.CampaignExternalResultsFinalCSR_Segment 
    (ClientServicesRef,SegmentID,
    ControlGroup,CustomerUniverse,Level,
    ControlGroupSize,Cardholders,Sales,Transactions,Spenders,
    IncrementalSales,IncrementalMargin,IncrementalTransactions,IncrementalSpenders,
    PooledStdDevSPC, DegreesOfFreedomSPC,
    PooledStdDevRR,DegreesOfFreedomRR,
    PooledStdDevSPS,DegreesOfFreedomSPS,
    QualyfingSales,Cashback,QualyfingCashback,
    Commission,CampaignCost,RewardOverride,IncrementalOverride)
    SELECT DISTINCT wm.ClientServicesRef, rf.SegmentID,
    wm.ControlGroup,wm.CustomerUniverse,wm.Level,
    SUM(rf.ControlGroupSize), SUM(rf.Cardholders),SUM(rf.Sales),SUM(rf.Transactions),SUM(rf.Spenders),
    SUM(rf.IncrementalSales),SUM(rf.IncrementalMargin),SUM(rf.IncrementalTransactions),SUM(rf.IncrementalSpenders),
    -- Assuming that Variance for SUM of Sales/Spenders/SPS is Average weigthed by number of Cardholders (or Spenders for SPS), and DF are just sum of DF
    -- It not 100% accurate (tends to underestimate) but the best estimate I could came up with without having to recalculate the variance
    SQRT(SUM(POWER(rf.PooledStdDevSPC,2)*1.0*rf.Cardholders)/SUM(rf.Cardholders)), SUM(rf.DegreesOfFreedomSPC),
    SQRT(SUM(POWER(rf.PooledStdDevRR,2)*1.0*rf.Cardholders)/SUM(rf.Cardholders)),SUM(rf.DegreesOfFreedomRR),
    CASE WHEN SUM(rf.Spenders)>0 THEN SQRT(SUM(POWER(rf.PooledStdDevRR,2)*1.0*rf.Spenders)/SUM(rf.Spenders)) ELSE 0 END,SUM(rf.DegreesOfFreedomSPS),
    SUM(rf.QualyfingSales),SUM(rf.Cashback),SUM(rf.QualyfingCashback),
    SUM(rf.Commission),SUM(rf.CampaignCost),SUM(rf.RewardOverride),SUM(rf.IncrementalOverride)
    FROM #Waves_Measured_Segment wm
    INNER JOIN Warehouse.MI.CampaignExternalResultsFinalWave_Segment rf  ON rf.ClientServicesRef=wm.ClientServicesRef
    WHERE NOT EXISTS (SELECT 1 FROM Warehouse.MI.CampaignExternalResultsFinalCSR_Segment old 
    WHERE old.ClientServicesRef=wm.ClientServicesRef AND old.SegmentID=rf.SegmentID)
    GROUP BY wm.ClientServicesRef, rf.SegmentID,
    wm.ControlGroup,wm.CustomerUniverse,wm.Level

    			 -- Uplif calculations
			 UPDATE Warehouse.MI.CampaignExternalResultsFinalCSR_Segment
			 SET SalesUplift=CASE WHEN IncrementalSales<Sales THEN 1.0*IncrementalSales/(Sales-IncrementalSales) ELSE IncrementalSales END
			   ,RRUplift=CASE WHEN IncrementalSpenders<Spenders THEN 1.0*IncrementalSpenders/(Sales-IncrementalSpenders) ELSE IncrementalSpenders END
			   ,ATVUplift=CASE WHEN IncrementalTransactions<Transactions AND IncrementalSales<Sales AND Transactions>0 THEN (1.0*Sales/Transactions)/(1.0*(Sales-IncrementalSales)/(Transactions-IncrementalTransactions))-1.0 ELSE 0 END
			   ,ATFUplift=CASE WHEN IncrementalSpenders<Spenders AND IncrementalTransactions<Transactions AND Spenders>0 THEN (1.0*Transactions/Spenders)/(1.0*(Transactions-IncrementalTransactions)/(Spenders-IncrementalSpenders))-1.0 ELSE 0 END
			   ,SPS_Diff=CASE WHEN IncrementalSpenders<Spenders AND IncrementalSales<Sales AND Spenders>0 THEN (1.0*Sales/Spenders)-(1.0*(Sales-IncrementalSales)/(Spenders-IncrementalSpenders)) ELSE 0 END
			 WHERE SalesUplift IS NULL

			 UPDATE Warehouse.MI.CampaignExternalResultsFinalCSR_Segment
			 SET MainDriver=CASE WHEN SalesUplift<=0 THEN 'N/A'
							 WHEN RRUplift>=ATVUplift AND RRUplift>=ATFUplift THEN 'RR'
							 WHEN ATVUplift>=ATFUplift THEN 'ATV' ELSE 'ATF' END
			 WHERE MainDriver IS NULL

			 UPDATE Warehouse.MI.CampaignExternalResultsFinalCSR_Segment SET
			 TScoreSPC=CASE WHEN PooledStdDevSPC>0 THEN ABS(1.0*IncrementalSales/Cardholders)/PooledStdDevSPC ELSE 0 END,
			 TScoreRR=CASE WHEN PooledStdDevRR>0 THEN ABS(1.0*IncrementalSpenders/Cardholders)/PooledStdDevRR ELSE 0 END,
			 TScoreSPS=CASE WHEN PooledStdDevSPS>0 THEN ABS(1.0*SPS_Diff)/PooledStdDevSPS ELSE 0 END
			 WHERE TScoreSPC IS NULL
    
			-- Significance calculations
			 UPDATE Warehouse.MI.CampaignExternalResultsFinalCSR_Segment SET
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
			 FROM Warehouse.MI.CampaignExternalResultsFinalCSR_Segment w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomSPC
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomSPC) and t.Tailes=2
			 WHERE PValueSPC IS NULL
    
			 UPDATE Warehouse.MI.CampaignExternalResultsFinalCSR_Segment SET
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
			 FROM Warehouse.MI.CampaignExternalResultsFinalCSR_Segment w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomRR
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomRR) and t.Tailes=2
			 WHERE PValueRR IS NULL

			 UPDATE Warehouse.MI.CampaignExternalResultsFinalCSR_Segment SET
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
			 FROM Warehouse.MI.CampaignExternalResultsFinalCSR_Segment w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomSPS
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomSPS) and t.Tailes=2
			 WHERE PValueSPS IS NULL

    -- List of all Campaigns (ClientServicesRef) that can be stored in CampaignExternalResultsFinalCSR_SuperSegment Tables (all the Waves were measured)
    IF OBJECT_ID('tempdb..#Waves_Measured_SuperSegment') IS NOT NULL DROP TABLE #Waves_Measured_SuperSegment
    SELECT  d.ClientServicesRef, COUNT(DISTINCT CONCAT(d.StartDate,d.SegmentID)) WavesLive,
    COUNT(DISTINCT CONCAT(rf.StartDate,rf.SegmentID)) WavesMeasured, 
    CASE WHEN COUNT(DISTINCT ControlGroup)>1 THEN 'Various' ELSE MAX(ControlGroup) END ControlGroup,
    CASE WHEN COUNT(DISTINCT CustomerUniverse)>1 THEN 'Various' ELSE MAX(CustomerUniverse) END CustomerUniverse,
    CASE WHEN COUNT(DISTINCT Level)>1 THEN 'Various' ELSE MAX(Level) END Level,
    MAX(rf.Inserted) Inserted
    INTO #Waves_Measured_SuperSegment
    FROM Warehouse.MI.CampaignDetailsWave_SuperSegment d
    LEFT JOIN Warehouse.MI.CampaignExternalResultsFinalWave_SuperSegment rf 
    ON rf.ClientServicesRef=d.ClientServicesRef AND rf.StartDate=d.StartDate AND rf.SegmentID=d.SegmentID
    GROUP BY d.ClientServicesRef
    HAVING COUNT(DISTINCT d.StartDate)=COUNT(DISTINCT rf.StartDate)

    INSERT INTO #Waves_Measured_SuperSegment
    SELECT * FROM #Waves_Measured m
    WHERE m.ClientServicesRef NOT IN (SELECT ClientServicesRef FROM #Waves_Measured_SuperSegment)

    -- Check if Results for uncompleted camapign are stored in CampaignExternalResultsFinalCSR, if yes delete them
    DELETE FROM csr
    FROM Warehouse.MI.CampaignDetailsCSR_SuperSegment csr
    WHERE csr.ClientServicesRef NOT IN 
	   (SELECT ClientServicesRef FROM #Waves_Measured_SuperSegment)

    -- Check if Results are already stored in CSR tables and if Wave results were modified afterwards, if yes delete them
    DELETE FROM csr
    FROM Warehouse.MI.CampaignDetailsCSR_SuperSegment csr
    INNER JOIN #Waves_Measured_SuperSegment wm ON wm.ClientServicesRef=csr.ClientServicesRef
    AND wm.Inserted>csr.Inserted -- Wave results modified, so CSR table needs to be updated accordingly

 -- Insert new results on CSR level as a sum of Wave results
    INSERT INTO Warehouse.MI.CampaignExternalResultsFinalCSR_SuperSegment 
    (ClientServicesRef,SegmentID,
    ControlGroup,CustomerUniverse,Level,
    ControlGroupSize,Cardholders,Sales,Transactions,Spenders,
    IncrementalSales,IncrementalMargin,IncrementalTransactions,IncrementalSpenders,
    PooledStdDevSPC, DegreesOfFreedomSPC,
    PooledStdDevRR,DegreesOfFreedomRR,
    PooledStdDevSPS,DegreesOfFreedomSPS,
    QualyfingSales,Cashback,QualyfingCashback,
    Commission,CampaignCost,RewardOverride,IncrementalOverride)
    SELECT DISTINCT wm.ClientServicesRef, rf.SegmentID,
    wm.ControlGroup,wm.CustomerUniverse,wm.Level,
    SUM(rf.ControlGroupSize), SUM(rf.Cardholders),SUM(rf.Sales),SUM(rf.Transactions),SUM(rf.Spenders),
    SUM(rf.IncrementalSales),SUM(rf.IncrementalMargin),SUM(rf.IncrementalTransactions),SUM(rf.IncrementalSpenders),
    -- Assuming that Variance for SUM of Sales/Spenders/SPS is Average weigthed by number of Cardholders (or Spenders for SPS), and DF are just sum of DF
    -- It not 100% accurate (tends to underestimate) but the best estimate I could came up with without having to recalculate the variance
    SQRT(SUM(POWER(rf.PooledStdDevSPC,2)*1.0*rf.Cardholders)/SUM(rf.Cardholders)), SUM(rf.DegreesOfFreedomSPC),
    SQRT(SUM(POWER(rf.PooledStdDevRR,2)*1.0*rf.Cardholders)/SUM(rf.Cardholders)),SUM(rf.DegreesOfFreedomRR),
    CASE WHEN SUM(rf.Spenders)>0 THEN SQRT(SUM(POWER(rf.PooledStdDevRR,2)*1.0*rf.Spenders)/SUM(rf.Spenders)) ELSE 0 END,SUM(rf.DegreesOfFreedomSPS),
    SUM(rf.QualyfingSales),SUM(rf.Cashback),SUM(rf.QualyfingCashback),
    SUM(rf.Commission),SUM(rf.CampaignCost),SUM(rf.RewardOverride),SUM(rf.IncrementalOverride)
    FROM #Waves_Measured_SuperSegment wm
    INNER JOIN Warehouse.MI.CampaignExternalResultsFinalWave_SuperSegment rf  ON rf.ClientServicesRef=wm.ClientServicesRef
    WHERE NOT EXISTS (SELECT 1 FROM Warehouse.MI.CampaignExternalResultsFinalCSR_SuperSegment old 
    WHERE old.ClientServicesRef=wm.ClientServicesRef AND old.SegmentID=rf.SegmentID)
    GROUP BY wm.ClientServicesRef, rf.SegmentID,
    wm.ControlGroup,wm.CustomerUniverse,wm.Level

    			 -- Uplif calculations
			 UPDATE Warehouse.MI.CampaignExternalResultsFinalCSR_SuperSegment
			 SET SalesUplift=CASE WHEN IncrementalSales<Sales THEN 1.0*IncrementalSales/(Sales-IncrementalSales) ELSE IncrementalSales END
			   ,RRUplift=CASE WHEN IncrementalSpenders<Spenders THEN 1.0*IncrementalSpenders/(Sales-IncrementalSpenders) ELSE IncrementalSpenders END
			   ,ATVUplift=CASE WHEN IncrementalTransactions<Transactions AND IncrementalSales<Sales AND Transactions>0 THEN (1.0*Sales/Transactions)/(1.0*(Sales-IncrementalSales)/(Transactions-IncrementalTransactions))-1.0 ELSE 0 END
			   ,ATFUplift=CASE WHEN IncrementalSpenders<Spenders AND IncrementalTransactions<Transactions AND Spenders>0 THEN (1.0*Transactions/Spenders)/(1.0*(Transactions-IncrementalTransactions)/(Spenders-IncrementalSpenders))-1.0 ELSE 0 END
			   ,SPS_Diff=CASE WHEN IncrementalSpenders<Spenders AND IncrementalSales<Sales AND Spenders>0 THEN (1.0*Sales/Spenders)-(1.0*(Sales-IncrementalSales)/(Spenders-IncrementalSpenders)) ELSE 0 END
			 WHERE SalesUplift IS NULL

			 UPDATE Warehouse.MI.CampaignExternalResultsFinalCSR_SuperSegment
			 SET MainDriver=CASE WHEN SalesUplift<=0 THEN 'N/A'
							 WHEN RRUplift>=ATVUplift AND RRUplift>=ATFUplift THEN 'RR'
							 WHEN ATVUplift>=ATFUplift THEN 'ATV' ELSE 'ATF' END
			 WHERE MainDriver IS NULL

			 UPDATE Warehouse.MI.CampaignExternalResultsFinalCSR_SuperSegment SET
			 TScoreSPC=CASE WHEN PooledStdDevSPC>0 THEN ABS(1.0*IncrementalSales/Cardholders)/PooledStdDevSPC ELSE 0 END,
			 TScoreRR=CASE WHEN PooledStdDevRR>0 THEN ABS(1.0*IncrementalSpenders/Cardholders)/PooledStdDevRR ELSE 0 END,
			 TScoreSPS=CASE WHEN PooledStdDevSPS>0 THEN ABS(1.0*SPS_Diff)/PooledStdDevSPS ELSE 0 END
			 WHERE TScoreSPC IS NULL
    
			-- Significance calculations
			 UPDATE Warehouse.MI.CampaignExternalResultsFinalCSR_SuperSegment SET
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
			 FROM Warehouse.MI.CampaignExternalResultsFinalCSR_SuperSegment w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomSPC
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomSPC) and t.Tailes=2
			 WHERE PValueSPC IS NULL
    
			 UPDATE Warehouse.MI.CampaignExternalResultsFinalCSR_SuperSegment SET
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
			 FROM Warehouse.MI.CampaignExternalResultsFinalCSR_SuperSegment w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomRR
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomRR) and t.Tailes=2
			 WHERE PValueRR IS NULL

			 UPDATE Warehouse.MI.CampaignExternalResultsFinalCSR_SuperSegment SET
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
			 FROM Warehouse.MI.CampaignExternalResultsFinalCSR_SuperSegment w
			 LEFT JOIN Warehouse.Stratification.TTestValues t on w.DegreesOfFreedomSPS
			 BETWEEN t.MinDegreesOfFreedom AND COALESCE(t.MaxDegreesOfFreedom,w.DegreesOfFreedomSPS) and t.Tailes=2
			 WHERE PValueSPS IS NULL

    -- Log that Store Procedure did not returned Error
    UPDATE Warehouse.MI.Campaign_Log
    SET ErrorMessage=0
    WHERE ID=@MY_ID

    -- Log when Store Procedure finished running
    UPDATE Warehouse.MI.Campaign_Log
    SET RunEndTime=GETDATE()
    WHERE ID=@MY_ID

END