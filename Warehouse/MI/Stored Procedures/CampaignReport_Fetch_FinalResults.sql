
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 13/08/2015
	Description: Gets campaign results for report creation on Final_Results page

	If the report is for the extended period then every other query (using the LTE
	tables) is removed by using the where clause

	======================= Change Log =======================

     26/09/2016 
	   - Extended version has become legacy and removed from the code

    01/11/2016
	   - Updated code to set incrementality metrics to 0 when they are < 0

***********************************************************************/
CREATE PROCEDURE [MI].[CampaignReport_Fetch_FinalResults]
(
	@ClientServicesRef varchar(40),
	@StartDate varchar(40),
	@Extended bit = 0
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT 
	   Effect
	   ,[Total Level]
	   ,ControlGroup
	   ,CustomerUniverse
	   ,AggregationLevel
	   ,Cardholders
	   ,Sales
	   ,Transactions
	   ,Spenders
	   ,CAsE WHEN IncrementalSales < 0 THEN 0 ELSE IncrementalSales END IncrementalSales
	   ,CASE WHEN IncrementalSales < 0 THEN NULL ELSE IncrementalMargin END IncrementalMargin
	   ,CASE WHEN IncrementalSales < 0 THEN 0 ELSE IncrementalTransactions END IncrementalTransactions
	   ,CASE WHEN IncrementalSales < 0 THEN 0 ELSE IncrementalSpenders END IncrementalSpenders
	   ,CASE WHEN SPS_Diff < 0 THEN 0 ELSE SPS_Diff END SPS_Diff
	   ,PooledStdDevSPC
	   ,DegreesOfFreedomSPC
	   ,TscoreSPC
	   ,PValueSPC
	   ,SignificantUpliftSPC
	   ,PooledStdDevRR
	   ,DegreesOfFreedomRR
	   ,TscoreRR
	   ,PValueRR
	   ,SignificantUpliftRR
	   ,PooledStdDevSPS
	   ,DegreesOfFreedomSPS
	   ,TscoreSPS
	   ,PValueSPS
	   ,SignificantUpliftSPS
	   ,QualyfingSales
	   ,Cashback
	   ,QualyfingCashback
	   ,Commission
	   ,CampaignCost
	   ,RewardOverride
	   ,CASE WHEN IncrementalSales < 0 THEN 0 ELSE IncrementalOverride END IncrementalOverride
	   ,ControlGroupSize   
    FROM (
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
		FROM Warehouse.MI.CampaignInternalResultsFinalWave
	    WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

	    UNION

	    SELECT Effect,'Total'
		    ,ControlGroup,CustomerUniverse,AggregationLevel
		    ,Cardholders,Sales,Transactions,Spenders
		    ,IncrementalSales,IncrementalMargin,IncrementalTransactions,IncrementalSpenders,SPS_Diff
		    ,PooledStdDevSPC,DegreesOfFreedomSPC,TscoreSPC,PValueSPC,SignificantUpliftSPC
		    ,PooledStdDevRR,DegreesOfFreedomRR,TscoreRR,PValueRR,SignificantUpliftRR
		    ,PooledStdDevSPS,DegreesOfFreedomSPS,TscoreSPS,PValueSPS,SignificantUpliftSPS
		    ,QualyfingSales,Cashback,QualyfingCashback,
		    Commission,CampaignCost,RewardOverride,IncrementalOverride
		    ,ControlGroupSize
		FROM Warehouse.MI.CampaignInternalResultsLTEFinalWave
	    WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate and @Extended = 1

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
		FROM Warehouse.MI.CampaignInternalResultsFinalWave_Segment
	    WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

	    UNION

	    SELECT Effect, CAST(SegmentID AS VARCHAR(MAX))
		    ,ControlGroup,CustomerUniverse,Level
		    ,Cardholders,Sales,Transactions,Spenders
		    ,IncrementalSales,IncrementalMargin,IncrementalTransactions,IncrementalSpenders,SPS_Diff
		    ,PooledStdDevSPC,DegreesOfFreedomSPC,TscoreSPC,PValueSPC,SignificantUpliftSPC
		    ,PooledStdDevRR,DegreesOfFreedomRR,TscoreRR,PValueRR,SignificantUpliftRR
		    ,PooledStdDevSPS,DegreesOfFreedomSPS,TscoreSPS,PValueSPS,SignificantUpliftSPS
		    ,QualyfingSales,Cashback,QualyfingCashback,
		    Commission,CampaignCost,RewardOverride,IncrementalOverride
		    ,ControlGroupSize
		FROM Warehouse.MI.CampaignInternalResultsLTEFinalWave_Segment
	    WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate and @Extended = 1

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
		FROM Warehouse.MI.CampaignInternalResultsFinalWave_SuperSegment
	    WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

	    UNION

	    SELECT Effect,CAST(SegmentID AS VARCHAR(MAX))
		    ,ControlGroup,CustomerUniverse,Level
		    ,Cardholders,Sales,Transactions,Spenders
		    ,IncrementalSales,IncrementalMargin,IncrementalTransactions,IncrementalSpenders,SPS_Diff
		    ,PooledStdDevSPC,DegreesOfFreedomSPC,TscoreSPC,PValueSPC,SignificantUpliftSPC
		    ,PooledStdDevRR,DegreesOfFreedomRR,TscoreRR,PValueRR,SignificantUpliftRR
		    ,PooledStdDevSPS,DegreesOfFreedomSPS,TscoreSPS,PValueSPS,SignificantUpliftSPS
		    ,QualyfingSales,Cashback,QualyfingCashback,
		    Commission,CampaignCost,RewardOverride,IncrementalOverride
		    ,ControlGroupSize
		FROM Warehouse.MI.CampaignInternalResultsLTEFinalWave_SuperSegment
	    WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate and @Extended = 1

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
		FROM Warehouse.MI.CampaignInternalResultsFinalWave_BespokeCell
	    WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate

	    UNION

	    SELECT Effect,CAST(Cell AS VARCHAR(MAX))
		    ,ControlGroup,CustomerUniverse,Level
		    ,Cardholders,Sales,Transactions,Spenders
		    ,IncrementalSales,IncrementalMargin,IncrementalTransactions,IncrementalSpenders,SPS_Diff
		    ,PooledStdDevSPC,DegreesOfFreedomSPC,TscoreSPC,PValueSPC,SignificantUpliftSPC
		    ,PooledStdDevRR,DegreesOfFreedomRR,TscoreRR,PValueRR,SignificantUpliftRR
		    ,PooledStdDevSPS,DegreesOfFreedomSPS,TscoreSPS,PValueSPS,SignificantUpliftSPS
		    ,QualyfingSales,Cashback,QualyfingCashback,
		    Commission,CampaignCost,RewardOverride,IncrementalOverride
		    ,ControlGroupSize
		FROM Warehouse.MI.CampaignInternalResultsLTEFinalWave_BespokeCell
	    WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate and @Extended = 1
    ) x
    ORDER BY 5 DESC,2, Cardholders DESC
 
END