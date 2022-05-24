

/********************************************************************************************
	Name: Staging.SSRS_R0180_OfferCountsReconciliation
	Desc: To display the offer counts for the selection week based on if the campaign is new, 
			or not within a 10% threshold of the previous cycle
	Auth: Zoe Taylor

	Change History
			ZT 11/12/2017	Report Created
			RF 23/10/2018	Process updated to pull all previous / ongoing activity rather that those that have a selection ran, allowing for a sum of counts per partner
	
*********************************************************************************************/


CREATE PROCEDURE [Staging].[SSRS_R0180_OfferCountsReconciliation_v5]

AS 
BEGIN
		
SET NOCOUNT ON	

CREATE TABLE #tempOfferCounts(
Publisher  varchar(100), 
AccountManager varchar(100), 
PartnerID varchar(100), 
PartnerName varchar(100), 
ClientServicesRef varchar(100), 
CampaignName varchar(255), 
CampaignNameReduced varchar(100), 
CampaignType varchar(100), 
IronOfferID int, 
OfferCampaign varchar(100), 
OfferSegment varchar(100), 
DemographicTargetting varchar(100), 
TopCashBackRate varchar(100), 
CampaignSetup varchar(100), 
CampaignCycleLength varchar(100), 
ControlGroupPercentage varchar(100), 
PredictedCardholderVolumes int, 
BriefLocation varchar(255), 
EmailDate date, 
UpcomingCount_Offer int, 
PreviousCount_Offer int, 
OutsideTolerance_Offer int, 
UpcomingCount_CSR int, 
PreviousCount_CSR int, 
OutsideTolerance_CSR int, 
UpcomingCount_Partner int, 
PreviousCount_Partner int, 
OutsideTolerance_Partner int
	)

INSERT #tempOfferCounts
exec WH_Virgin.[Report].[SSRS_V0004_OfferCountsReconciliation_AllHistoric]


INSERT #tempOfferCounts
exec Warehouse.[Staging].[SSRS_R0180_OfferCountsReconciliation_v5]


select *
from #tempOfferCounts

--drop table #tempOfferCounts

END
