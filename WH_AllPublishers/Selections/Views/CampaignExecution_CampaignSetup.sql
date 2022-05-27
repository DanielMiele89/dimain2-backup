
CREATE VIEW [Selections].[CampaignExecution_CampaignSetup]
AS

SELECT	ShopperSegmentTypeID = sst.Item
	,	IronOfferID = iof.Item
	,	PartnerID = cs.PartnerID
	,	ClientServicesRef = cs.ClientServicesRef
	,	StartDate = cs.StartDate
	,	EndDate = cs.EndDate
	,	ID = cs.ID
	,	ClubID = cs.ClubID
	,	ClubName = cs.ClubName
	,	TableSource = cs.TableSource
FROM (	SELECT	DISTINCT
				ShopperSegmentTypeID = 'Acquire,Lapsed,Shopper,Welcome,11,12'
			,	IronOfferID = cs.OfferID
			,	PartnerID = cs.PartnerID
			,	ClientServicesRef = cs.ClientServicesRef
			,	StartDate = cs.StartDate
			,	EndDate = cs.EndDate
			,	ID = cs.ID
			,	ClubID =	CASE
								WHEN DatabaseName = 'Warehouse' THEN 132
								WHEN DatabaseName = 'WH_Virgin' THEN 166
								WHEN DatabaseName = 'WH_VirginPCA' THEN 182
								WHEN DatabaseName = 'WH_Visa' THEN 180
							END
			,	ClubName =	CASE
								WHEN DatabaseName = 'Warehouse' THEN 'MyRewards'
								WHEN DatabaseName = 'WH_Virgin' THEN 'Virgin CC'
								WHEN DatabaseName = 'WH_VirginPCA' THEN 'Virgin PCA'
								WHEN DatabaseName = 'WH_Visa' THEN 'Visa Barclaycard'
							END
			,	TableSource = '[' + DatabaseName + '].[Selections].[' + TableName + ']'
		FROM [WH_AllPublishers].[Selections].[CampaignSetup_All] cs) cs
CROSS APPLY [WH_AllPublishers].[dbo].[il_SplitDelimitedStringArray] (ShopperSegmentTypeID, ',') sst
CROSS APPLY [WH_AllPublishers].[dbo].[il_SplitDelimitedStringArray] (IronOfferID, ',') iof
WHERE sst.ItemNumber = iof.ItemNumber
AND iof.Item != 0

