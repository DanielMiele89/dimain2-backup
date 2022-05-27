CREATE VIEW [Selections].[CampaignSetup_POS]
AS

SELECT	'Warehouse' AS DatabaseName
	,	'CampaignSetup_POS' AS TableName
	,	*
FROM [Warehouse].[Selections].[CampaignSetup_POS]
UNION ALL
SELECT	'Warehouse' AS DatabaseName
	,	'CampaignSetup_DD' AS TableName
	,	*
FROM [Warehouse].[Selections].[CampaignSetup_DD]
UNION ALL
SELECT	'WH_Virgin' AS DatabaseName
	,	'CampaignSetup_POS' AS TableName
	,	*
FROM [WH_Virgin].[Selections].[CampaignSetup_POS]
UNION ALL
SELECT	'WH_VirginPCA' AS DatabaseName
	,	'CampaignSetup_POS' AS TableName
	,	*
FROM [WH_VirginPCA].[Selections].[CampaignSetup_POS]
UNION ALL
SELECT	'WH_Visa' AS DatabaseName
	,	'CampaignSetup_POS' AS TableName
	,	*
FROM [WH_Visa].[Selections].[CampaignSetup_POS]