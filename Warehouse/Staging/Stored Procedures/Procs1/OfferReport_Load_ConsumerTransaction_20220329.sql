/******************************************************************************
PROCESS NAME: Offer Calculation - Calculate Performance - Fetch CT Metrics

Author		Rory Francis
Created		12/01/2021
Purpose		Stores subset of the transactions required for processing

Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [Staging].[OfferReport_Load_ConsumerTransaction_20220329]

AS
BEGIN

	DECLARE @StartDate DATETIME
		,	@EndDate DATETIME

	SELECT	@StartDate = MIN(StartDate)
		,	@EndDate = MAX(EndDate)
	FROM [Staging].[OfferReport_AllOffers]

	TRUNCATE TABLE [Staging].[OfferReport_ConsumerTransaction]
	INSERT INTO [Staging].[OfferReport_ConsumerTransaction]
	SELECT	ct.ConsumerCombinationID
		,	ct.TranDate
		,	ct.CINID
		,	ct.Amount
		,	ct.IsOnline
		,	1 AS IsWarehouse
		,	0 AS IsVirgin
		,	0 AS IsVisaBarclaycard
	FROM [Relational].[ConsumerTransaction] ct
	WHERE ct.TranDate BETWEEN @StartDate AND @EndDate
	AND EXISTS (	SELECT 1
					FROM [Staging].[OfferReport_ConsumerCombinations] cc
					WHERE ct.ConsumerCombinationID = cc.ConsumerCombinationID
					AND cc.IsWarehouse = 1)
	UNION ALL
	SELECT	ct.ConsumerCombinationID
		,	ct.TranDate
		,	ct.CINID
		,	ct.Amount
		,	ct.IsOnline
		,	0 AS IsWarehouse
		,	1 AS IsVirgin
		,	0 AS IsVisaBarclaycard
	FROM [WH_Virgin].[Trans].[ConsumerTransaction] ct
	WHERE ct.TranDate BETWEEN @StartDate AND @EndDate
	AND EXISTS (	SELECT 1
					FROM [Staging].[OfferReport_ConsumerCombinations] cc
					WHERE ct.ConsumerCombinationID = cc.ConsumerCombinationID
					AND cc.IsVirgin = 1)
	UNION ALL
	SELECT	ct.ConsumerCombinationID
		,	ct.TranDate
		,	ct.CINID
		,	ct.Amount
		,	ct.IsOnline
		,	0 AS IsWarehouse
		,	0 AS IsVirgin
		,	1 AS IsVisaBarclaycard
	FROM [WH_Visa].[Trans].[ConsumerTransaction] ct
	WHERE ct.TranDate BETWEEN @StartDate AND @EndDate
	AND EXISTS (	SELECT 1
					FROM [Staging].[OfferReport_ConsumerCombinations] cc
					WHERE ct.ConsumerCombinationID = cc.ConsumerCombinationID
					AND cc.IsVisaBarclaycard = 1)
					
	--CREATE CLUSTERED INDEX CIX_CCID ON [Warehouse].[Staging].[OfferReport_ConsumerTransaction] (ConsumerCombinationID)
	--CREATE NONCLUSTERED INDEX IX_CINID ON [Warehouse].[Staging].[OfferReport_ConsumerTransaction] (CINID)
	--CREATE NONCLUSTERED INDEX IX_CCDateAmount_IncCIN ON [Warehouse].[Staging].[OfferReport_ConsumerTransaction] ([ConsumerCombinationID],[TranDate],[Amount]) INCLUDE ([CINID])

	--CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON [Warehouse].[Staging].[OfferReport_ConsumerTransaction] (CINID, ConsumerCombinationID, Amount, TranDate, IsOnline, IsWarehouse, IsVirgin, IsVisaBarclaycard) ON Warehouse_Columnstores

END






