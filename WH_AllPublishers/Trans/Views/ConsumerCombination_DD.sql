
CREATE VIEW [Trans].[ConsumerCombination_DD]
AS

SELECT	CONVERT(VARCHAR(50), 'Warehouse') AS DataSource
	,	mr.ConsumerCombinationID_DD
	,	CONVERT(VARCHAR(50), 'Warehouse_') + CONVERT(VARCHAR(50), mr.ConsumerCombinationID_DD) AS CCID_DataSource
	,	mr.BrandID
	,	mr.OIN
	,	mr.Narrative_RBS
	,	mr.Narrative_VF
FROM [Warehouse].[Relational].[ConsumerCombination_DD] mr
