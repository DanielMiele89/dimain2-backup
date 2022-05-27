
/**********************************************************************

	Author:		 Hayden Reid
	Create date: 13/08/2015
	Description:

***********************************************************************/
CREATE PROCEDURE [MI].[CampaignReport_Fetch_ReportValues] 
(
	@PartnerID int
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
 
	    select DISTINCT s.ClientServicesRef, StartDate, EndDate, SplitName, p.PartnerName,
		   s.CashbackRate
		  , SpendStretch
		  , Cardholders
		  , Spenders
		  , TotalSales
		  ,  Transactions
		  ,  CampaignCost
		  ,  PValueSPC
		  ,  Uplift
		  ,  ATVUplift
		  ,  ATFUplift
		  ,  SpenderUplift
		  ,  IncrementalSales
		  ,  IncrementalSpenders
		  ,  Incrementaltransactions
		  --, (SELECT PValueSPC FROM MI.CampaignExternalResultsFinalWave w where w.ClientServicesRef = s.ClientServicesRef and w.StartDate = s.StartDate) TotalPValue
		  , TotalPValue
		  from prototype.CampaignResults_FullWaveResults s
	    join relational.ironoffer_campaign_htm ih on ih.clientservicesref = s.clientservicesref
	    join relational.partner p on p.partnerid = ih.PartnerID
	    where ih.PartnerID = @PartnerID
END




