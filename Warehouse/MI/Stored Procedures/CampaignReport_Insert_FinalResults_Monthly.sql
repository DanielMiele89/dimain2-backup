
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 13/08/2015
	Description: Gets campaign results for report creation on Final_Results page

	If the report is for the extended period then every other query (using the LTE
	tables) is removed by using the where clause

***********************************************************************/
CREATE PROCEDURE [MI].[CampaignReport_Insert_FinalResults_Monthly]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
    IF OBJECT_ID('Warehouse.MI.CampaignReport_Staging_Monthly_Results') IS NOT NULL DROP TABLE Warehouse.MI.CampaignReport_Staging_Monthly_Results
    SELECT distinct ih.IronOfferID, AllResults.* INTO Warehouse.MI.CampaignReport_Staging_Monthly_Results  FROM (
        SELECT DISTINCT * FROM (
	   SELECT distinct a.ClientServicesRef, a.StartDate, i.CalcStartDate, i.CalcEndDate, 'During campaign' 'Effect','Total' 'Total Level'
		  ,w.ControlGroup,w.CustomerUniverse,AggregationLevel
		  ,Cardholders,Sales,Transactions,Spenders
		  ,w.IncrementalSales,IncrementalMargin,w.IncrementalTransactions,w.IncrementalSpenders,w.SPS_Diff
		  ,PooledStdDevSPC,DegreesOfFreedomSPC,TscoreSPC,PValueSPC,SignificantUpliftSPC
		  ,PooledStdDevRR,DegreesOfFreedomRR,TscoreRR,PValueRR,SignificantUpliftRR
		  ,PooledStdDevSPS,DegreesOfFreedomSPS,TscoreSPS,PValueSPS,SignificantUpliftSPS
		  ,QualyfingSales,Cashback,QualyfingCashback,
		  Commission,CampaignCost,RewardOverride,IncrementalOverride
		  ,ControlGroupSize
	   FROM Warehouse.MI.CampaignExternalResultsFinalWave_Incomplete w
	   JOIN Warehouse.MI.CampaignReportLog_Incomplete i on i.ClientServicesRef = w.ClientServicesRef and i.CalcStartDate = w.StartDate
	   JOIN Warehouse.MI.CampaignReport_Staging_AllCampaigns a on a.ClientServicesRef = w.ClientServicesRef and a.StartDate = i.StartDate
		  and isIncomplete = 1
	   LEFT JOIN Warehouse.MI.CampaignExternalResults_Workings_Incomplete wo 
		  on wo.ClientServicesRef = w.ClientServicesRef
		  and wo.CustomerUniverse = w.CustomerUniverse
		  and wo.Level = w.AggregationLevel
		  and wo.StartDate = w.StartDate

	   UNION

	   --SELECT a.ClientServicesRef, a.StartDate, i.CalcEndDate, 'During campaign',CAST(SegmentID AS VARCHAR(MAX))
		  --,ControlGroup,CustomerUniverse,Level
		  --,Cardholders,Sales,Transactions,Spenders
		  --,IncrementalSales,IncrementalMargin,IncrementalTransactions,IncrementalSpenders,SPS_Diff
		  --,PooledStdDevSPC,DegreesOfFreedomSPC,TscoreSPC,PValueSPC,SignificantUpliftSPC
		  --,PooledStdDevRR,DegreesOfFreedomRR,TscoreRR,PValueRR,SignificantUpliftRR
		  --,PooledStdDevSPS,DegreesOfFreedomSPS,TscoreSPS,PValueSPS,SignificantUpliftSPS
		  --,QualyfingSales,Cashback,QualyfingCashback,
		  --Commission,CampaignCost,RewardOverride,IncrementalOverride
		  --,ControlGroupSize
	   --FROM Warehouse.MI.CampaignExternalResultsFinalWave_Segment_Incomplete w
	   --JOIN Warehouse.MI.CampaignReportLog_Incomplete i on i.ClientServicesRef = w.ClientServicesRef and i.CalcStartDate = w.StartDate
	   --JOIN Warehouse.MI.CampaignReport_Staging_AllCampaigns a on a.ClientServicesRef = w.ClientServicesRef and a.StartDate = i.StartDate 
	   --and isIncomplete = 1

	   --UNION

	   --SELECT a.ClientServicesRef, a.StartDate, i.CalcEndDate, 'During campaign',CAST(SegmentID AS VARCHAR(MAX))
		  --,ControlGroup,CustomerUniverse,Level
		  --,Cardholders,Sales,Transactions,Spenders
		  --,IncrementalSales,IncrementalMargin,IncrementalTransactions,IncrementalSpenders,SPS_Diff
		  --,PooledStdDevSPC,DegreesOfFreedomSPC,TscoreSPC,PValueSPC,SignificantUpliftSPC
		  --,PooledStdDevRR,DegreesOfFreedomRR,TscoreRR,PValueRR,SignificantUpliftRR
		  --,PooledStdDevSPS,DegreesOfFreedomSPS,TscoreSPS,PValueSPS,SignificantUpliftSPS
		  --,QualyfingSales,Cashback,QualyfingCashback,
		  --Commission,CampaignCost,RewardOverride,IncrementalOverride
		  --,ControlGroupSize
	   --FROM Warehouse.MI.CampaignExternalResultsFinalWave_SuperSegment_Incomplete w
	   --JOIN Warehouse.MI.CampaignReportLog_Incomplete i on i.ClientServicesRef = w.ClientServicesRef and i.CalcStartDate = w.StartDate
	   --JOIN Warehouse.MI.CampaignReport_Staging_AllCampaigns a on a.ClientServicesRef = w.ClientServicesRef and a.StartDate = i.StartDate 
	   --and isIncomplete = 1

	   --UNION


	   SELECT DISTINCT a.ClientServicesRef, a.StartDate, i.CalcStartDate, i.CalcEndDate, 'During campaign',CAST(w.Cell AS VARCHAR(MAX))
		  ,w.ControlGroup,w.CustomerUniverse,w.Level
		  ,Cardholders,Sales,Transactions,Spenders
		  ,w.IncrementalSales,IncrementalMargin,w.IncrementalTransactions,w.IncrementalSpenders,w.SPS_Diff
		  ,PooledStdDevSPC,DegreesOfFreedomSPC,TscoreSPC,PValueSPC,SignificantUpliftSPC
		  ,PooledStdDevRR,DegreesOfFreedomRR,TscoreRR,PValueRR,SignificantUpliftRR
		  ,PooledStdDevSPS,DegreesOfFreedomSPS,TscoreSPS,PValueSPS,SignificantUpliftSPS
		  ,QualyfingSales,Cashback,QualyfingCashback,
		  Commission,CampaignCost,RewardOverride,IncrementalOverride
		  ,ControlGroupSize
	   FROM Warehouse.MI.CampaignExternalResultsFinalWave_BespokeCell_Incomplete w
	   JOIN Warehouse.MI.CampaignReportLog_Incomplete i on i.ClientServicesRef = w.ClientServicesRef and i.CalcStartDate = w.StartDate
	   JOIN Warehouse.MI.CampaignReport_Staging_AllCampaigns a on a.ClientServicesRef = w.ClientServicesRef and a.StartDate = i.StartDate 
	   and isIncomplete = 1
    	   JOIN Warehouse.MI.CampaignExternalResults_Workings_Incomplete wo 
		  on wo.ClientServicesRef = w.ClientServicesRef
		  and wo.CustomerUniverse = w.CustomerUniverse
		  and wo.Level = w.Level
		  and wo.StartDate = w.StartDate
    ) IncompleteResults

    UNION ALL

    SELECT DISTINCT * FROM (
	   SELECT a.ClientServicesRef, a.StartDate, a.StartDate CalcStartDate, a.EndDate, 'During campaign' 'Effect','Total' 'Total Level'
		  ,ControlGroup,CustomerUniverse,AggregationLevel
		  ,Cardholders,Sales,Transactions,Spenders
		  ,IncrementalSales,IncrementalMargin,IncrementalTransactions,IncrementalSpenders,SPS_Diff
		  ,PooledStdDevSPC,DegreesOfFreedomSPC,TscoreSPC,PValueSPC,SignificantUpliftSPC
		  ,PooledStdDevRR,DegreesOfFreedomRR,TscoreRR,PValueRR,SignificantUpliftRR
		  ,PooledStdDevSPS,DegreesOfFreedomSPS,TscoreSPS,PValueSPS,SignificantUpliftSPS
		  ,QualyfingSales,Cashback,QualyfingCashback,
		  Commission,CampaignCost,RewardOverride,IncrementalOverride
		  ,ControlGroupSize
	   FROM Warehouse.MI.CampaignExternalResultsFinalWave w
	   JOIN Warehouse.MI.CampaignReport_Staging_AllCampaigns a on a.StartDate = w.StartDate 
	   and a.ClientServicesRef = w.ClientServicesRef and a.StartDate = w.StartDate 
	   and isIncomplete = 0 and isCalculated = 1

	   --UNION

	   --SELECT a.ClientServicesRef, a.StartDate, a.EndDate, 'During campaign',CAST(SegmentID AS VARCHAR(MAX))
		  --,ControlGroup,CustomerUniverse,Level
		  --,Cardholders,Sales,Transactions,Spenders
		  --,IncrementalSales,IncrementalMargin,IncrementalTransactions,IncrementalSpenders,SPS_Diff
		  --,PooledStdDevSPC,DegreesOfFreedomSPC,TscoreSPC,PValueSPC,SignificantUpliftSPC
		  --,PooledStdDevRR,DegreesOfFreedomRR,TscoreRR,PValueRR,SignificantUpliftRR
		  --,PooledStdDevSPS,DegreesOfFreedomSPS,TscoreSPS,PValueSPS,SignificantUpliftSPS
		  --,QualyfingSales,Cashback,QualyfingCashback,
		  --Commission,CampaignCost,RewardOverride,IncrementalOverride
		  --,ControlGroupSize
	   --FROM Warehouse.MI.CampaignExternalResultsFinalWave_Segment w
	   --JOIN Warehouse.MI.CampaignReport_Staging_AllCampaigns a on a.StartDate = w.StartDate 
	   --and a.ClientServicesRef = w.ClientServicesRef and a.StartDate = w.StartDate 
	   --and isIncomplete = 0 and isCalculated = 1

	   --UNION

	   --SELECT a.ClientServicesRef, a.StartDate, a.EndDate, 'During campaign',CAST(SegmentID AS VARCHAR(MAX))
		  --,ControlGroup,CustomerUniverse,Level
		  --,Cardholders,Sales,Transactions,Spenders
		  --,IncrementalSales,IncrementalMargin,IncrementalTransactions,IncrementalSpenders,SPS_Diff
		  --,PooledStdDevSPC,DegreesOfFreedomSPC,TscoreSPC,PValueSPC,SignificantUpliftSPC
		  --,PooledStdDevRR,DegreesOfFreedomRR,TscoreRR,PValueRR,SignificantUpliftRR
		  --,PooledStdDevSPS,DegreesOfFreedomSPS,TscoreSPS,PValueSPS,SignificantUpliftSPS
		  --,QualyfingSales,Cashback,QualyfingCashback,
		  --Commission,CampaignCost,RewardOverride,IncrementalOverride
		  --,ControlGroupSize
	   --FROM Warehouse.MI.CampaignExternalResultsFinalWave_SuperSegment w
	   --JOIN Warehouse.MI.CampaignReport_Staging_AllCampaigns a on a.StartDate = w.StartDate 
	   --and a.ClientServicesRef = w.ClientServicesRef and a.StartDate = w.StartDate 
	   --and isIncomplete = 0 and isCalculated = 1 

	   UNION

	   SELECT DISTINCT a.ClientServicesRef, a.StartDate, a.StartDate, a.EndDate, 'During campaign',CAST(Cell AS VARCHAR(MAX))
		  ,ControlGroup,CustomerUniverse,Level
		  ,Cardholders,Sales,Transactions,Spenders
		  ,IncrementalSales,IncrementalMargin,IncrementalTransactions,IncrementalSpenders,SPS_Diff
		  ,PooledStdDevSPC,DegreesOfFreedomSPC,TscoreSPC,PValueSPC,SignificantUpliftSPC
		  ,PooledStdDevRR,DegreesOfFreedomRR,TscoreRR,PValueRR,SignificantUpliftRR
		  ,PooledStdDevSPS,DegreesOfFreedomSPS,TscoreSPS,PValueSPS,SignificantUpliftSPS
		  ,QualyfingSales,Cashback,QualyfingCashback,
		  Commission,CampaignCost,RewardOverride,IncrementalOverride
		  ,ControlGroupSize
	   FROM Warehouse.MI.CampaignExternalResultsFinalWave_BespokeCell w
	   JOIN Warehouse.MI.CampaignReport_Staging_AllCampaigns a on a.StartDate = w.StartDate 
	   and a.ClientServicesRef = w.ClientServicesRef and a.StartDate = w.StartDate 
	   and isIncomplete = 0 and isCalculated = 1
    ) CompleteResults
) AllResults
LEFT JOIN (
    SELECT DISTINCT ClientServicesRef, StartDate, Level FROM MI.CampaignExternalResultsFinalWave_BespokeCell_Incomplete
) bi on bi.ClientServicesRef = AllResults.ClientServicesRef and bi.StartDate = AllResults.CalcStartDate
left join mi.campaignreport_offersplit b on b.ClientServicesRef = AllResults.ClientServicesRef and b.SplitName = AllResults.[Total Level]
join relational.IronOffer_Campaign_HTM ih on ih.IronOfferID = b.IronOfferID or (ih.ClientServicesRef = AllResults.ClientServicesRef and b.ClientServicesRef is null)
WHERE (bi.ClientServicesRef is null or AllResults.AggregationLevel = 'Bespoke Total')
END