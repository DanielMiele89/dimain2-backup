
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 13/08/2015
	Description: Gets campaign results for report creation on Final_Results page

	If the report is for the extended period then every other query (using the LTE
	tables) is removed by using the where clause

***********************************************************************/
CREATE PROCEDURE [MI].[CampaignReport_Insert_FinalResults_MB]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
    IF OBJECT_ID('Warehouse.MI.CampaignReport_Staging_Monthly_Results') IS NOT NULL DROP TABLE Warehouse.MI.CampaignReport_Staging_Monthly_Results

    SELECT x.* INTO Warehouse.MI.CampaignReport_Staging_Monthly_Results
     FROM (
	   SELECT distinct w.ClientServicesRef, i.StartDate, i.CalcStartDate, i.CalcEndDate,  'During campaign' 'Effect','Total' 'Total Level'
		  ,w.ControlGroup,w.CustomerUniverse,AggregationLevel
		  ,Cardholders,Sales,Transactions,Spenders
		  ,w.IncrementalSales,IncrementalMargin,w.IncrementalTransactions,w.IncrementalSpenders,w.SPS_Diff
		  ,PooledStdDevSPC,DegreesOfFreedomSPC,TscoreSPC,PValueSPC,SignificantUpliftSPC
		  ,PooledStdDevRR,DegreesOfFreedomRR,TscoreRR,PValueRR,SignificantUpliftRR
		  ,PooledStdDevSPS,DegreesOfFreedomSPS,TscoreSPS,PValueSPS,SignificantUpliftSPS
		  ,QualyfingSales,Cashback,QualyfingCashback,
		  Commission,CampaignCost,RewardOverride,IncrementalOverride
		  ,ControlGroupSize, wo.Cardholders_C, wo.Sales_C, wo.Transactions_C, ih.CashbackRate/100 MailedOfferRate
	   FROM Warehouse.MI.CampaignExternalResultsFinalWave_Incomplete w
	   JOIN Warehouse.Relational.IronOffer_Campaign_HTM ih on ih.ClientServicesRef = w.ClientServicesRef
	   JOIN Warehouse.Relational.Partner p on p.PartnerID = ih.PartnerID
	   JOIN Warehouse.Relational.Brand b on b.BrandID = p.BrandID
	   JOIN Warehouse.MI.CampaignReportLog_Incomplete i on i.ClientServicesRef = w.ClientServicesRef and i.CalcStartDate = w.StartDate
	   JOIN Warehouse.MI.CampaignExternalResults_Workings_Incomplete wo 
		  on wo.ClientServicesRef = w.ClientServicesRef
		  and wo.CustomerUniverse = w.CustomerUniverse
		  and wo.Level = w.AggregationLevel
		  and wo.StartDate = w.StartDate
		  and wo.ControlGroup = w.ControlGroup
		  and wo.SalesType = 'Main Results (Qualifying MIDs or Channels Only)'
	   WHERE BrandGroupID = 42

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


	   SELECT DISTINCT w.ClientServicesRef, i.StartDate, i.CalcStartDate, i.CalcEndDate, 'During campaign',CAST(w.Cell AS VARCHAR(MAX))
		  ,w.ControlGroup,w.CustomerUniverse,w.Level
		  ,Cardholders,Sales,Transactions,Spenders
		  ,w.IncrementalSales,IncrementalMargin,w.IncrementalTransactions,w.IncrementalSpenders,w.SPS_Diff
		  ,PooledStdDevSPC,DegreesOfFreedomSPC,TscoreSPC,PValueSPC,SignificantUpliftSPC
		  ,PooledStdDevRR,DegreesOfFreedomRR,TscoreRR,PValueRR,SignificantUpliftRR
		  ,PooledStdDevSPS,DegreesOfFreedomSPS,TscoreSPS,PValueSPS,SignificantUpliftSPS
		  ,QualyfingSales,Cashback,QualyfingCashback,
		  Commission,CampaignCost,RewardOverride,IncrementalOverride
		  ,ControlGroupSize, wo.Cardholders_C, wo.Sales_C, wo.Transactions_C, ih.CashbackRate/100 MailedOfferRate
	   FROM Warehouse.MI.CampaignExternalResultsFinalWave_BespokeCell_Incomplete w
	   JOIN Warehouse.MI.CampaignReportLog_Incomplete i on i.ClientServicesRef = w.ClientServicesRef and i.CalcStartDate = w.StartDate
	   JOIN Warehouse.MI.CampaignReport_OfferSplit os on os.ClientServicesRef = w.ClientServicesRef and os.SplitName = w.Cell
	   JOIN Warehouse.Relational.IronOffer_Campaign_HTM ih on ih.ClientServicesRef = w.ClientServicesRef and ih.IronOfferID = os.IronOfferID
	   JOIN Warehouse.Relational.Partner p on p.PartnerID = ih.PartnerID
	   JOIN Warehouse.Relational.Brand b on b.BrandID = p.BrandID
    	   JOIN Warehouse.MI.CampaignExternalResults_Workings_Incomplete wo 
		  on wo.ClientServicesRef = w.ClientServicesRef
		  and wo.CustomerUniverse = w.CustomerUniverse
		  and wo.Level = w.Level
		  and wo.StartDate = w.StartDate
		  and wo.ControlGroup = w.ControlGroup
		  and wo.Cell = w.Cell
		  and wo.SalesType = 'Main Results (Qualifying MIDs or Channels Only)'
	WHERE BrandGroupID = 42

	
    ) x
    LEFT JOIN (
	   SELECT DISTINCT ClientServicesRef, StartDate, Level FROM MI.CampaignExternalResultsFinalWave_BespokeCell_Incomplete
    ) bi on bi.ClientServicesRef = x.ClientServicesRef and bi.StartDate = x.CalcStartDate

    WHERE bi.ClientServicesRef is null or x.AggregationLevel = 'Bespoke Total'


END

