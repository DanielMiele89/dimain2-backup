
CREATE VIEW [Selections].[ROCShopperSegment_SelectionCounts]
AS

SELECT	[EmailDate]
	,	[OutputTableName]
	,	[IronOfferID]
	,	[CountSelected]
	,	[RunDateTime]
	,	[NewCampaign]
	,	[ClientServicesRef]
FROM [Selections].[CampaignExecution_SelectionCounts]