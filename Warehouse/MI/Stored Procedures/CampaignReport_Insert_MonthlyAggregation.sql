
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 13/08/2015
	Description: Gets campaign results for report creation on Final_Results page

	If the report is for the extended period then every other query (using the LTE
	tables) is removed by using the where clause

***********************************************************************/
CREATE PROCEDURE [MI].[CampaignReport_Insert_MonthlyAggregation]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
    INSERT INTO MI.CampaignResults_MonthlyAggregation
    SELECT io.IronOfferID
	   , 143 as PublisherID
	   , io.PartnerID
	   , os.SplitName as OfferName
	   , m.Cardholders
	   , m.Transactions
	   , m.Sales
	   , m.IncrementalSpenders
	   , m.IncrementalTransactions
	   , m.IncrementalSales
    FROM Warehouse.MI.CampaignReport_Staging_Monthly_Results m
    JOIN Relational.IronOffer io on io.IronOfferID = m.IronOfferID
    left join mi.CampaignReport_OfferSplit os on os.IronOfferID = m.IronOfferID
    where m.CalcStartDate between '2016-01-01' and '2016-01-31'

    
END


