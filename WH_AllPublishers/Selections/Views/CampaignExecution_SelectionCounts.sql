



CREATE VIEW [Selections].[CampaignExecution_SelectionCounts]
AS

SELECT	'Warehouse' AS DatabaseName
	,	EmailDate
	,	IronOfferID
	,	CountSelected
	,	ClientServicesRef
	,	OutputTableName
FROM [Warehouse].[Selections].[CampaignSelectionCounts_DD]
UNION ALL
SELECT	'WH_Virgin' AS DatabaseName
	,	EmailDate
	,	IronOfferID
	,	CountSelected
	,	ClientServicesRef
	,	OutputTableName
FROM [WH_Virgin].[Selections].[CampaignExecution_SelectionCounts]
UNION ALL
SELECT	'WH_VirginPCA' AS DatabaseName
	,	EmailDate
	,	IronOfferID
	,	CountSelected
	,	ClientServicesRef
	,	OutputTableName
FROM [WH_VirginPCA].[Selections].[CampaignExecution_SelectionCounts]
UNION ALL
SELECT	'WH_Visa' AS DatabaseName
	,	EmailDate
	,	IronOfferID
	,	CountSelected
	,	ClientServicesRef
	,	OutputTableName
FROM [WH_Visa].[Selections].[CampaignExecution_SelectionCounts]
--ORDER BY	EmailDate
--		,	ClientServicesRef
--		,	IronOfferID

