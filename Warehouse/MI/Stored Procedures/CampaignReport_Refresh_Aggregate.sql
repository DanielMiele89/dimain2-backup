
/***********************************************************************

	Author:		 Hayden Reid
	Create date: 13/08/2015
	Description: Get the list of reports to generate

	Refreshes aggregated table for publisher-agnostic shopper segment reports

	======================= Change Log =======================

***********************************************************************/


CREATE PROCEDURE [MI].[CampaignReport_Refresh_Aggregate] 
AS
BEGIN
	
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#T1') IS NOT NULL DROP TABLE #T1

-- Get top level offers
SELECT distinct COALESCE(sl.ToplevelOffer, s.IronOfferID) GroupedIronOfferID
    , s.IronOfferID
    , s.StartDate, s.EndDate
    , COALESCE(sl.AlternateName, s.SplitName) SplitName
    , CashbackRate
    , SpendStretch
    , Cardholders
    , Spenders
    , TotalSales
    , Transactions
    , CampaignCost
    , PValueSPC
    , IncrementalSales
    , IncrementalSpenders
    , IncrementalTransactions
    , TotalPValue
    , Universe
    , CASE WHEN COALESCE(sl.nfi, CASE Universe WHEN 'Warehouse' THEN 0 ELSE 1 END) = 1 THEN io.PartnerID ELSE iio.PartnerID END PartnerID
INTO #T1
FROM Prototype.CampaignResults_FullWaveResults s
JOIN Prototype.CampaignReport_ShopperSegmentLink3 sl on sl.TopLevelOffer = s.IronOfferID
LEFT JOIN nfi.Relational.IronOffer io on io.ID = s.IronOfferID
LEFT JOIN Warehouse.Relational.IronOffer iio on iio.IronOfferID = s.IronOfferID

-- Get bottom level offers
INSERT INTO #T1
SELECT DISTINCT COALESCE(sl.ToplevelOffer, s.IronOfferID) GroupedIronOfferID
    , S.IronOfferID
    , s.StartDate, s.EndDate
    , COALESCE(sl.AlternateName, s.SplitName) SplitName
    , CashbackRate
    , SpendStretch
    , Cardholders
    , Spenders
    , TotalSales
    , Transactions
    , CampaignCost
    , PValueSPC
    , IncrementalSales
    , IncrementalSpenders
    , IncrementalTransactions
    , TotalPValue
    , Universe
    , CASE WHEN COALESCE(sl.nfi, CASE Universe WHEN 'Warehouse' THEN 0 ELSE 1 END) = 0 THEN io.PartnerID ELSE iio.PartnerID END PartnerID
FROM Prototype.CampaignResults_FullWaveResults s
JOIN Prototype.CampaignReport_ShopperSegmentLink3 sl on sl.BottomLevelOffer = s.IronOfferID
LEFT JOIN nfi.Relational.IronOffer io on io.ID = s.IronOfferID
LEFT JOIN Warehouse.Relational.IronOffer iio on iio.IronOfferID = s.IronOfferID

-- Get remaining ungrouped offers
INSERT INTO #T1
SELECT DISTINCT s.IronOfferID GroupedIronOfferID
    , s.IronOfferID
    , s.StartDate, s.EndDate
    , SplitName
    , CashbackRate
    , SpendStretch
    , Cardholders
    , Spenders
    , TotalSales
    , Transactions
    , CampaignCost
    , PValueSPC
    , IncrementalSales
    , IncrementalSpenders
    , IncrementalTransactions
    , TotalPValue
    , Universe
    , CASE WHEN (CASE Universe WHEN 'Warehouse' THEN 0 ELSE 1 END) = 1 THEN io.PartnerID ELSE iio.PartnerID END PartnerID
FROM Prototype.CampaignResults_FullWaveResults s
LEFT JOIN nfi.Relational.IronOffer io on io.ID = s.IronOfferID
LEFT JOIN Warehouse.Relational.IronOffer iio on iio.IronOfferID = s.IronOfferID
WHERE NOT EXISTS (SELECT 1 FROM #T1 t WHERE t.IronOfferID = s.IronOfferID)


-- Merge up RBS Offers and calculate incremental metrics
IF OBJECT_ID('tempdb..#T2') IS NOT NULL DROP TABLE #T2
SELECT distinct
    *
    , CAST(IncrementalSales as real)/NULLIF((cast(TotalSales as real)- cast(IncrementalSales as real)),0)  Uplift
    , ( (cast(TotalSales as real)/NULLIF((cast(Transactions as real)),0)) / ( NULLIF((cast(TotalSales as real)-cast(IncrementalSales as real)),0) / NULLIF((cast(Transactions as real)-cast(IncrementalTransactions as real)), 0) ) ) -1 as ATVUplift
    , ( (cast(Transactions as real)/NULLIF(cast(Spenders as real), 0)) / ( NULLIF((cast(Transactions as real)-cast(IncrementalTransactions as real)),0) / NULLIF((cast(Spenders as real)- cast(IncrementalSpenders as real)),0)) ) -1  as ATFUplift
    ,  cast(IncrementalSpenders as real)/NULLIF((cast(Spenders as real)- cast(IncrementalSpenders as real)),0)  SpendersUplift
INTO #T2
FROM (select GroupedIronOfferID
	   , MAX(StartDate) StartDate
	   , MAX(EndDate) EndDate
	   , MIN(SplitName) SplitName
	   , MAX(CashbackRate) CashbackRate
	   , MAX(SpendStretch) SpendStretch
	   , SUM(Cardholders) Cardholders
	   , SUM(Spenders) Spenders
	   , SUM(TotalSales) TotalSales
	   , SUM(Transactions) Transactions
	   , SUM(CampaignCost) CampaignCost
	   , MAX(PValueSPC) PValueSPC
	   , SUM(IncrementalSales) IncrementalSales
	   , SUM(IncrementalSpenders) IncrementalSpendErs
	   , SUM(IncrementalTransactions) IncrementalTransactions
	   , MAX(TotalPValue) TotalPValue
	   , MAX(PartnerID) PartnerID
    FROM #T1 t
    WHERE Universe = 'Warehouse'
    GROUP BY GroupedIronOfferID, StartDate, EndDate
) x

order by partnerid, StartDate

INSERT INTO #T2
SELECT GroupedIronOfferID, StartDate, EndDate, SPlitName, Cashbackrate, SpendStretch, Cardholders, Spenders, TotalSales, Transactions, CampaignCost, PValueSPC, INcrementalSales, IncrementalSpenders, IncrementalTransactions, TotalPValue, PartnerID, NULL, NULL, NULL, NULL
FROM #T1
WHERE Universe <> 'Warehouse'


INSERT INTO #T2
SELECT IronOfferID, StartDate, EndDate, SplitName, CashbackRate, SpendStretch, Cardholders, Spenders, TotalSales, Transactions, CampaignCost, PVAlueSPC, IncrementalSales, IncrementalSpenders, IncrementalTransactions, TotalPValue, PartnerID, Uplift, ATVUplift, ATFUplift, SpenderUplift
FROM Warehouse.Prototype.CampaignResults_HistoricalResults


IF OBJECT_ID('Warehouse.Prototype.CampaignResults_Aggregate') IS NOT NULL DROP TABLE Warehouse.Prototype.CampaignResults_Aggregate
SELECT x.*, p.PartnerName
into Warehouse.Prototype.CampaignResults_Aggregate
FROM (
    select GroupedIronOfferID
	   , MAX(StartDate) StartDate
	   , MAX(EndDate) EndDate
	   , MIN(SplitName) SplitName
	   , MAX(CashbackRate) CashbackRate
	   , MAX(SpendStretch) SpendStretch
	   , SUM(Cardholders) Cardholders
	   , SUM(Spenders) Spenders
	   , SUM(TotalSales) TotalSales
	   , SUM(Transactions) Transactions
	   , SUM(CampaignCost) CampaignCost
	   , MAX(PValueSPC) PValueSPC
	   , SUM(IncrementalSales) IncrementalSales
	   , SUM(IncrementalSpenders) IncrementalSpendErs
	   , SUM(IncrementalTransactions) IncrementalTransactions
	   , MAX(TotalPValue) TotalPValue
	   , MAX(PartnerID) PartnerID
	   , MAX(Uplift) Uplift
	   , MAX(SpendersUplift) SpendersUplift
	   , MAX(ATVUplift) ATVUplift
	   , MAX(ATFUplift) ATFUplift
    from #T2
    where (SplitName not like '%Launch%'
	   and SplitName not like '%Base%'
	   and SplitName not like '%Welcome%') or (PartnerID = 4588)
    GROUP BY GroupedIronOfferID, StartDate, EndDate
) x
LEFT JOIN Relational.Partner p on p.PartnerID = x.PartnerID

	  	   
END





