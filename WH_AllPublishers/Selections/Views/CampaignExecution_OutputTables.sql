

CREATE VIEW [Selections].[CampaignExecution_OutputTables]
AS

SELECT	'Warehouse' AS DatabaseName
	,	PreSelection_ALS_ID
	,	PartnerID
	,	OutputTableName
	,	PriorityFlag
	,	InPartnerDedupe
	,	RowNumber
FROM [Warehouse].[Selections].[CampaignExecution_OutputTables]
UNION ALL
SELECT	'WH_Virgin' AS DatabaseName
	,	PreSelection_ALS_ID
	,	PartnerID
	,	OutputTableName
	,	PriorityFlag
	,	InPartnerDedupe
	,	RowNumber
FROM [WH_Virgin].[Selections].[CampaignExecution_OutputTables]
UNION ALL
SELECT	'WH_VirginPCA' AS DatabaseName
	,	PreSelection_ALS_ID
	,	PartnerID
	,	OutputTableName
	,	PriorityFlag
	,	InPartnerDedupe
	,	RowNumber
FROM [WH_VirginPCA].[Selections].[CampaignExecution_OutputTables]
UNION ALL
SELECT	'WH_Visa' AS DatabaseName
	,	PreSelection_ALS_ID
	,	PartnerID
	,	OutputTableName
	,	PriorityFlag
	,	InPartnerDedupe
	,	RowNumber
FROM [WH_Visa].[Selections].[CampaignExecution_OutputTables]

