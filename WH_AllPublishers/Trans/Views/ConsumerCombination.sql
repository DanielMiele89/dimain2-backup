
CREATE VIEW [Trans].[ConsumerCombination]
AS

SELECT	CONVERT(VARCHAR(50), 'Warehouse') AS DataSource
	,	mr.ConsumerCombinationID
	,	CONVERT(VARCHAR(50), 'Warehouse_') + CONVERT(VARCHAR(50), mr.ConsumerCombinationID) AS CCID_DataSource
	,	mr.BrandID
	,	mr.MID
	,	mr.Narrative
	,	mr.LocationCountry
	,	mr.MCCID
	,	mr.OriginatorID
	,	mr.IsHighVariance
	,	mr.IsUKSpend
	,	mr.PaymentGatewayStatusID
FROM [Warehouse].[Relational].[ConsumerCombination] mr
UNION ALL
SELECT	'WH_Virgin' AS DataSource
	,	vir.ConsumerCombinationID
	,	CONVERT(VARCHAR(50), 'WH_Virgin_') + CONVERT(VARCHAR(50), vir.ConsumerCombinationID) AS CCID_DataSource
	,	vir.BrandID
	,	vir.MID
	,	vir.Narrative
	,	vir.LocationCountry
	,	vir.MCCID
	,	NULL AS OriginatorID
	,	vir.IsHighVariance
	,	vir.IsUKSpend
	,	vir.PaymentGatewayStatusID
FROM [WH_Virgin].[Trans].[ConsumerCombination] vir
UNION ALL
SELECT	'WH_Visa' AS DataSource
	,	vis.ConsumerCombinationID
	,	CONVERT(VARCHAR(50), 'WH_Visa_') + CONVERT(VARCHAR(50), vis.ConsumerCombinationID) AS CCID_DataSource
	,	vis.BrandID
	,	vis.MID
	,	vis.Narrative
	,	vis.LocationCountry
	,	vis.MCCID
	,	NULL AS OriginatorID
	,	vis.IsHighVariance
	,	vis.IsUKSpend
	,	vis.PaymentGatewayStatusID
FROM [WH_Visa].[Trans].[ConsumerCombination] vis
