
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 13/08/2015
	Description:

***********************************************************************/
CREATE PROCEDURE [MI].[CampaignReport_Fetch_ReportValues_NEW] 
(
    @PartnerID int
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    select 
	   GroupedIronOfferID
	   , StartDate
	   , EndDate
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
	   , IncrementalSpendErs
	   , IncrementalTransactions
	   , TotalPValue
	   , PartnerID
	   , ISNULL(Uplift, 0) Uplift
	   , ISNULL(SpendersUplift, 0) SpendersUplift
	   , ISNULL(ATVUplift, 0) ATVUplift
	   , ISNULL(ATFUplift, 0) ATFUplift
    from Warehouse.prototype.campaignresults_aggregate
    WHERE PartnerID = @PartnerID
	   and cashbackrate is not null



END