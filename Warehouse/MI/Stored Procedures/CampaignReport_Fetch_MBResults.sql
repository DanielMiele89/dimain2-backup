
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 13/08/2015
	Description:

***********************************************************************/
CREATE PROCEDURE [MI].[CampaignReport_Fetch_MBResults] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
 
    select distinct 
	   p.PartnerName
	   , t.ClientServicesRef
	   , t.CalcStartDate
	   , t.CalcEndDate
	   , y.SpendStretch
	   , Cardholders
	   , ControlGroupSize
	   , Transactions
	--   , IncrementalTransactions
	   , Sales
	 --  , IncrementalSales 
	   , AggregationLevel [Total Level]
	  -- , AggregationLevel
	   , t.MailedOfferRate
	   , QualyfingCashback
	   , t.Sales_C
	   , t.Transactions_C
    from Warehouse.MI.CampaignReport_Staging_Monthly_Results t
    join Relational.IronOffer_Campaign_HTM ih on ih.ClientServicesRef = t.ClientServicesRef
    Join relational.IronOffer io on io.IronOfferID = ih.IronOfferID and io.StartDate = t.StartDate
    JOIN Relational.Partner p on p.PartnerID = ih.PartnerID
    LEFT JOIN (
	   SELECT ClientServicesRef, MIN(MinimumBasketSize) SpendStretch 
	   FROM Warehouse.Relational.IronOffer_PartnerCommissionRule pcr 
	   JOIN Relational.IronOffer_Campaign_HTM ii on ii.IronOfferID = pcr.IronOfferID
	   WHERE pcr.IronOfferID = ii.IronOfferID and TypeID = 1 and Status = 1 and MinimumBasketSize > 0
	   GROUP BY ClientServicesRef, MinimumBasketSize
    ) y on y.ClientServicesRef = t.ClientServicesRef
    order by 2, 3


END






