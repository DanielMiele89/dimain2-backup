
CREATE VIEW [Selections].[CampaignCode_Selections_OutputTables]
AS

SELECT	PreSelection_ALS_ID
	,	PartnerID
	,	OutputTableName
	,	PriorityFlag
	,	InPartnerDedupe
	,	RowNumber
FROM [Selections].[CampaignExecution_OutputTables]

