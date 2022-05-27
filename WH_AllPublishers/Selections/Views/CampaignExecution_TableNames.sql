

CREATE VIEW [Selections].[CampaignExecution_TableNames]
AS

SELECT	'Warehouse' AS DatabaseName
	,	TableID
	,	TableName
	,	ClientServicesRef
FROM [Warehouse].[Selections].[CampaignExecution_TableNames]
UNION ALL
SELECT	'WH_Virgin' AS DatabaseName
	,	TableID
	,	TableName
	,	ClientServicesRef
FROM [WH_Virgin].[Selections].[CampaignExecution_TableNames]
UNION ALL
SELECT	'WH_VirginPCA' AS DatabaseName
	,	TableID
	,	TableName
	,	ClientServicesRef
FROM [WH_VirginPCA].[Selections].[CampaignExecution_TableNames]
UNION ALL
SELECT	'WH_Visa' AS DatabaseName
	,	TableID
	,	TableName
	,	ClientServicesRef
FROM [WH_Visa].[Selections].[CampaignExecution_TableNames]

