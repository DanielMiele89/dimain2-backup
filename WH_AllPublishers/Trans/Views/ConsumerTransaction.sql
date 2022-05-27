


CREATE VIEW [Trans].[ConsumerTransaction]
AS

SELECT	CONVERT(VARCHAR(50), 'Warehouse') AS DataSource
	,	mr.ConsumerCombinationID
	,	mr.CINID
	,	mr.Amount
	,	mr.IsOnline
	,	mr.TranDate
FROM [Warehouse].[Relational].[ConsumerTransaction] mr
UNION ALL
SELECT	CONVERT(VARCHAR(50), 'Warehouse') AS DataSource
	,	mr.ConsumerCombinationID
	,	mr.CINID
	,	mr.Amount
	,	mr.IsOnline
	,	mr.TranDate
FROM [Warehouse].[Relational].[ConsumerTransaction_CreditCard] mr
UNION ALL
SELECT	CONVERT(VARCHAR(50), 'WH_Virgin') AS DataSource
	,	vir.ConsumerCombinationID
	,	vir.CINID
	,	vir.Amount
	,	vir.IsOnline
	,	vir.TranDate
FROM [WH_Virgin].[Trans].[ConsumerTransaction] vir
UNION ALL
SELECT	CONVERT(VARCHAR(50), 'WH_VirginPCA') AS DataSource
	,	vir.ConsumerCombinationID
	,	vir.CINID
	,	vir.Amount
	,	vir.IsOnline
	,	vir.TranDate
FROM [WH_VirginPCA].[Trans].[ConsumerTransaction] vir
UNION ALL
SELECT	CONVERT(VARCHAR(50), 'WH_Visa') AS DataSource
	,	vis.ConsumerCombinationID
	,	vis.CINID
	,	vis.Amount
	,	vis.IsOnline
	,	vis.TranDate
FROM [WH_Visa].[Trans].[ConsumerTransaction] vis
