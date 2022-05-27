
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 22/08/2016
	Description: Gets campaign results for report creation on Final_Results page


***********************************************************************/
CREATE PROCEDURE [MI].[CampaignReport_Fetch_FinalResults_Incomplete]
(
	@ClientServicesRef varchar(40),
	@StartDate varchar(40)
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

SELECT 'During campaign' 'Effect','Total' 'Total Level'
      ,ControlGroup,CustomerUniverse,AggregationLevel
      ,Cardholders,Sales,Transactions,Spenders
      ,IncrementalSales,IncrementalMargin,IncrementalTransactions,IncrementalSpenders,SPS_Diff
      ,PooledStdDevSPC,DegreesOfFreedomSPC,TscoreSPC,PValueSPC,SignificantUpliftSPC
	 ,PooledStdDevRR,DegreesOfFreedomRR,TscoreRR,PValueRR,SignificantUpliftRR
      ,PooledStdDevSPS,DegreesOfFreedomSPS,TscoreSPS,PValueSPS,SignificantUpliftSPS
      ,QualyfingSales,Cashback,QualyfingCashback,
	 Commission,CampaignCost,RewardOverride,IncrementalOverride
	 ,ControlGroupSize
  FROM Warehouse.MI.CampaignExternalResultsFinalWave_Incomplete
 WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

 UNION

 SELECT 'During campaign',CAST(SegmentID AS VARCHAR(MAX))
      ,ControlGroup,CustomerUniverse,Level
      ,Cardholders,Sales,Transactions,Spenders
      ,IncrementalSales,IncrementalMargin,IncrementalTransactions,IncrementalSpenders,SPS_Diff
      ,PooledStdDevSPC,DegreesOfFreedomSPC,TscoreSPC,PValueSPC,SignificantUpliftSPC
	 ,PooledStdDevRR,DegreesOfFreedomRR,TscoreRR,PValueRR,SignificantUpliftRR
      ,PooledStdDevSPS,DegreesOfFreedomSPS,TscoreSPS,PValueSPS,SignificantUpliftSPS
      ,QualyfingSales,Cashback,QualyfingCashback,
	 Commission,CampaignCost,RewardOverride,IncrementalOverride
	 ,ControlGroupSize
  FROM Warehouse.MI.CampaignExternalResultsFinalWave_Segment_Incomplete
 WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

 UNION

 SELECT 'During campaign',CAST(SegmentID AS VARCHAR(MAX))
      ,ControlGroup,CustomerUniverse,Level
      ,Cardholders,Sales,Transactions,Spenders
      ,IncrementalSales,IncrementalMargin,IncrementalTransactions,IncrementalSpenders,SPS_Diff
      ,PooledStdDevSPC,DegreesOfFreedomSPC,TscoreSPC,PValueSPC,SignificantUpliftSPC
	 ,PooledStdDevRR,DegreesOfFreedomRR,TscoreRR,PValueRR,SignificantUpliftRR
      ,PooledStdDevSPS,DegreesOfFreedomSPS,TscoreSPS,PValueSPS,SignificantUpliftSPS
      ,QualyfingSales,Cashback,QualyfingCashback,
	 Commission,CampaignCost,RewardOverride,IncrementalOverride
	 ,ControlGroupSize
  FROM Warehouse.MI.CampaignExternalResultsFinalWave_SuperSegment_Incomplete
 WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

 UNION

  SELECT TOP 36 'During campaign',CAST(Cell AS VARCHAR(MAX))
      ,ControlGroup,CustomerUniverse,Level
      ,Cardholders,Sales,Transactions,Spenders
      ,IncrementalSales,IncrementalMargin,IncrementalTransactions,IncrementalSpenders,SPS_Diff
      ,PooledStdDevSPC,DegreesOfFreedomSPC,TscoreSPC,PValueSPC,SignificantUpliftSPC
	 ,PooledStdDevRR,DegreesOfFreedomRR,TscoreRR,PValueRR,SignificantUpliftRR
      ,PooledStdDevSPS,DegreesOfFreedomSPS,TscoreSPS,PValueSPS,SignificantUpliftSPS
      ,QualyfingSales,Cashback,QualyfingCashback,
	 Commission,CampaignCost,RewardOverride,IncrementalOverride
	 ,ControlGroupSize
  FROM Warehouse.MI.CampaignExternalResultsFinalWave_BespokeCell_Incomplete
 WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

END




