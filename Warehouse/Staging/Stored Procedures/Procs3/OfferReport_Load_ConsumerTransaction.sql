/******************************************************************************
PROCESS NAME: Offer Calculation - Calculate Performance - Fetch CT Metrics

Author		Rory Francis
Created		12/01/2021
Purpose		Stores subset of the transactions required for processing

Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [Staging].[OfferReport_Load_ConsumerTransaction]

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
		,	PublisherID = 132
		,	IsWarehouse = 1
		,	IsVirgin = 0
		,	IsVirginPCA = 0
		,	IsVisaBarclaycard = 0
	FROM [Relational].[ConsumerTransaction] ct
	WHERE ct.TranDate BETWEEN @StartDate AND @EndDate
	AND EXISTS (	SELECT 1
					FROM [Staging].[OfferReport_ConsumerCombinations] cc
					WHERE ct.ConsumerCombinationID = cc.ConsumerCombinationID
					AND cc.PublisherID = 132)
	UNION ALL
	SELECT	ct.ConsumerCombinationID
		,	ct.TranDate
		,	ct.CINID
		,	ct.Amount
		,	ct.IsOnline
		,	PublisherID = 166
		,	IsWarehouse = 0
		,	IsVirgin = 1
		,	IsVirginPCA = 0
		,	IsVisaBarclaycard = 0
	FROM [WH_Virgin].[Trans].[ConsumerTransaction] ct
	WHERE ct.TranDate BETWEEN @StartDate AND @EndDate
	AND EXISTS (	SELECT 1
					FROM [Staging].[OfferReport_ConsumerCombinations] cc
					WHERE ct.ConsumerCombinationID = cc.ConsumerCombinationID
					AND cc.PublisherID = 166)
	UNION ALL
	SELECT	ct.ConsumerCombinationID
		,	ct.TranDate
		,	ct.CINID
		,	ct.Amount
		,	ct.IsOnline
		,	PublisherID = 182
		,	IsWarehouse = 0
		,	IsVirgin = 0
		,	IsVirginPCA = 1
		,	IsVisaBarclaycard = 0
	FROM [WH_VirginPCA].[Trans].[ConsumerTransaction] ct
	WHERE ct.TranDate BETWEEN @StartDate AND @EndDate
	AND EXISTS (	SELECT 1
					FROM [Staging].[OfferReport_ConsumerCombinations] cc
					WHERE ct.ConsumerCombinationID = cc.ConsumerCombinationID
					AND cc.PublisherID = 182)
	UNION ALL
	SELECT	ct.ConsumerCombinationID
		,	ct.TranDate
		,	ct.CINID
		,	ct.Amount
		,	ct.IsOnline
		,	PublisherID = 180
		,	IsWarehouse = 0
		,	IsVirgin = 0
		,	IsVirginPCA = 0
		,	IsVisaBarclaycard = 1
	FROM [WH_Visa].[Trans].[ConsumerTransaction] ct
	WHERE ct.TranDate BETWEEN @StartDate AND @EndDate
	AND EXISTS (	SELECT 1
					FROM [Staging].[OfferReport_ConsumerCombinations] cc
					WHERE ct.ConsumerCombinationID = cc.ConsumerCombinationID
					AND cc.PublisherID = 180)
					
	--CREATE CLUSTERED INDEX CIX_CCID ON [Warehouse].[Staging].[OfferReport_ConsumerTransaction] (ConsumerCombinationID)
	--CREATE NONCLUSTERED INDEX IX_CINID ON [Warehouse].[Staging].[OfferReport_ConsumerTransaction] (CINID)
	--CREATE NONCLUSTERED INDEX IX_CCDateAmount_IncCIN ON [Warehouse].[Staging].[OfferReport_ConsumerTransaction] ([ConsumerCombinationID],[TranDate],[Amount]) INCLUDE ([CINID])

	--CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON [Warehouse].[Staging].[OfferReport_ConsumerTransaction] (CINID, ConsumerCombinationID, Amount, TranDate, IsOnline, IsWarehouse, IsVirgin, IsVisaBarclaycard) ON Warehouse_Columnstores

END