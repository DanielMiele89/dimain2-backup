

/********************************************************************************************
	Name: SSRS_R0180_OfferCountsReconciliation
	Desc: Upcoming and all previous results for both, Virgin and myRewards
	Auth: William Allen

	Change History:
			
	
*********************************************************************************************/


CREATE PROCEDURE [Report].[SSRS_R0180_OfferCountsReconciliation]

AS 
BEGIN
		
	SET NOCOUNT ON	


	IF OBJECT_ID('tempdb..#tempOfferCounts') IS NOT NULL
		DROP TABLE #tempOfferCounts
	CREATE TABLE #tempOfferCounts(
		Publisher					varchar(100), 
		AccountManager				varchar(100), 
		PartnerID					varchar(100), 
		PartnerName					varchar(100), 
		ClientServicesRef			varchar(100), 
		CampaignName				varchar(255), 
		CampaignNameReduced			varchar(100), 
		CampaignType				varchar(100), 
		IronOfferID					int, 
		OfferCampaign				varchar(100), 
		OfferSegment				varchar(100), 
		DemographicTargetting		varchar(100), 
		TopCashBackRate				varchar(100), 
		CampaignSetup				varchar(100), 
		CampaignCycleLength			varchar(100), 
		ControlGroupPercentage		varchar(100), 
		PredictedCardholderVolumes	int, 
		BriefLocation				varchar(255), 
		EmailDate					date, 
		UpcomingCount_Offer			int, 
		PreviousCount_Offer			int, 
		OutsideTolerance_Offer		int, 
		UpcomingCount_CSR			int, 
		PreviousCount_CSR			int, 
		OutsideTolerance_CSR		int, 
		UpcomingCount_Partner		int, 
		PreviousCount_Partner		int, 
		OutsideTolerance_Partner	int
	)

	INSERT #tempOfferCounts
	EXEC WH_Virgin.[Report].[SSRS_V0004_OfferCountsReconciliation_AllHistoric]


	INSERT #tempOfferCounts
	EXEC Warehouse.[Staging].[SSRS_R0180_OfferCountsReconciliation_v5]


	SELECT	*
	FROM	#tempOfferCounts



END
