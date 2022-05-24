
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 13/08/2015
	Description:

***********************************************************************/
CREATE PROCEDURE [MI].[CampaignReport_FetchWave_RBSResults] 
(
	@ClientServicesRef varchar(40),
	@StartDate varchar(40),
	@Extended bit = 0,
	@Both bit = 0,
	@Inc bit = 1
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

DECLARE @Like nvarchar(15) = (SELECT MIN(Level) FROM Warehouse.MI.CampaignExternalResults_Workings WHERE ClientServicesRef = @ClientServicesRef and StartDate = @StartDate)

SET @Like = CASE @Like WHEN 'Total' THEN 'Total' WHEN 'Segment' THEN 'Total' ELSE 'Bespoke%' END
SELECT DISTINCT * FROM (

SELECT io.IronOfferID 
    , ClientServicesRef
    , io.StartDate
    , io.EndDate
    , [Total level]
    , 'Warehouse' 'DBUniverse'
    , io.TopCashbackRate
    , COALESCE(MIN(MinimumBasketSize), 0) as SpendStretch
    , Cardholders
    , Spenders
    , Sales
    , IncrementalSales
    , Transactions
    , IncrementalSpenders
    , IncrementalTransactions
    , CampaignCost
    , PValueSPC
    , CASE @Inc WHEN 1 THEN CAST(IncrementalSales as real)/NULLIF((cast(Sales as real)- cast(IncrementalSales as real)),0) ELSE NULL END Uplift
    , CASE @Inc WHEN 1 THEN ( (cast(Sales as real)/NULLIF((cast(Transactions as real)),0)) / ( NULLIF((cast(Sales as real)-cast(IncrementalSales as real)),0) / NULLIF((cast(Transactions as real)-cast(IncrementalTransactions as real)), 0) ) ) -1 ELSE NULL END as ATVUplift
    , CASE @Inc WHEN 1 THEN ( (cast(Transactions as real)/NULLIF(cast(Spenders as real), 0)) / ( NULLIF((cast(Transactions as real)-cast(IncrementalTransactions as real)),0) / NULLIF((cast(Spenders as real)- cast(IncrementalSpenders as real)),0)) ) -1 ELSE NULL END as ATFUplift
    , CASE @Inc WHEN 1 THEN  cast(IncrementalSpenders as real)/NULLIF((cast(Spenders as real)- cast(IncrementalSpenders as real)),0) ELSE NULL END SpendersUplift
    , (SELECT PValueSPC FROM MI.CampaignExternalResultsFinalWave w where w.ClientServicesRef = o.ClientServicesRef and w.StartDate = io.StartDate) TotalPValue
    , NULL Notes

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
	 FROM Warehouse.MI.CampaignExternalResultsFinalWave
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
	 FROM Warehouse.MI.CampaignExternalResultsLTEFinalWave
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
	 FROM Warehouse.MI.CampaignExternalResultsFinalWave_Segment
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
	 FROM Warehouse.MI.CampaignExternalResultsLTEFinalWave_Segment
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
	 FROM Warehouse.MI.CampaignExternalResultsFinalWave_SuperSegment
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
	 FROM Warehouse.MI.CampaignExternalResultsLTEFinalWave_SuperSegment
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
	 FROM Warehouse.MI.CampaignExternalResultsFinalWave_BespokeCell
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
	 FROM Warehouse.MI.CampaignExternalResultsLTEFinalWave_BespokeCell
	WHERE ClientServicesRef=@ClientServicesRef AND StartDate=@StartDate and @Extended = 1
) x
LEFT JOIN Warehouse.MI.CampaignReport_OfferSplit o on o.SplitName = x.[Total Level] and o.ClientServicesRef = @ClientServicesRef
JOIN Warehouse.Relational.IronOffer io on io.IronOfferID = o.IronOfferID and io.StartDate = @StartDate
LEFT JOIN Warehouse.Relational.IronOffer_PartnerCommissionRule pcr
    on pcr.IronOfferID = io.IronOfferID
	   and TypeID = 1 and Status = 1 and MinimumBasketSize > 0
WHERE x.AggregationLevel like @Like and io.PartnerID <> 4523
group by io.IronOfferID
    , ClientServicesRef
    , io.StartDate
    , io.EndDate
    , [Total level]
    , io.TopCashbackRate
    , Cardholders
    , Spenders
    , Sales
    , IncrementalSales
    , Transactions
    , IncrementalSpenders
    , IncrementalTransactions
    , CampaignCost
    , PValueSPC


UNION ALL

SELECT io.IronOfferID 
    , o.ClientServicesRef
    , io.StartDate
    , io.EndDate
    , [Total level]
    , 'Warehouse'
    , io.TopCashbackRate
    , COALESCE(MIN(MinimumBasketSize), 0) as SpendStretch
    , Cardholders
    , Spenders
    , Sales
    , IncrementalSales
    , Transactions
    , IncrementalSpenders
    , IncrementalTransactions
    , CampaignCost
    , PValueSPC
    , CASE @Inc WHEN 1 THEN CAST(IncrementalSales as real)/NULLIF((cast(Sales as real)- cast(IncrementalSales as real)),0) ELSE NULL END Uplift
    , CASE @Inc WHEN 1 THEN ( (cast(Sales as real)/NULLIF((cast(Transactions as real)),0)) / ( NULLIF((cast(Sales as real)-cast(IncrementalSales as real)),0) / NULLIF((cast(Transactions as real)-cast(IncrementalTransactions as real)), 0) ) ) -1 ELSE NULL END as ATVUplift
    , CASE @Inc WHEN 1 THEN ( (cast(Transactions as real)/NULLIF(cast(Spenders as real), 0)) / ( NULLIF((cast(Transactions as real)-cast(IncrementalTransactions as real)),0) / NULLIF((cast(Spenders as real)- cast(IncrementalSpenders as real)),0)) ) -1 ELSE NULL END as ATFUplift
    ,CASE @Inc WHEN 1 THEN  cast(IncrementalSpenders as real)/NULLIF((cast(Spenders as real)- cast(IncrementalSpenders as real)),0) ELSE NULL END SpendersUplift
    , (SELECT PValueSPC FROM MI.CampaignExternalResultsFinalWave w where w.ClientServicesRef = o.ClientServicesRef and w.StartDate = io.StartDate) TotalPValue
    , NULL Notes
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
LEFT JOIN Warehouse.MI.CampaignReport_OfferSplit o on o.SplitName = x.[Total Level] and o.ClientServicesRef = @ClientServicesRef
JOIN Warehouse.Relational.IronOffer io on io.IronOfferID = o.IronOfferID and io.StartDate = @StartDate
LEFT JOIN Warehouse.Relational.IronOffer_PartnerCommissionRule pcr
    on pcr.IronOfferID = io.IronOfferID
	   and TypeID = 1 and Status = 1 and MinimumBasketSize > 0
WHERE x.AggregationLevel like @Like and @Both = 1 and io.PartnerID <> 4523
group by io.IronOfferID
    , ClientServicesRef
    , io.StartDate
    , io.EndDate
    , [Total level]
    , io.TopCashbackRate
    , Cardholders
    , Spenders
    , Sales
    , IncrementalSales
    , Transactions
    , IncrementalSpenders
    , IncrementalTransactions
    , CampaignCost
    , PValueSPC
 ) x
END