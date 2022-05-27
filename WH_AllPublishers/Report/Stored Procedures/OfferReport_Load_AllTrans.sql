/******************************************************************************
PROCESS NAME: Offer Calculation - Calculate Performance - Fetch CT Metrics

Author		Rory Francis
Created		12/01/2021
Purpose		Stores subset of the transactions required for processing

Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [Report].[OfferReport_Load_AllTrans]

AS
BEGIN

		TRUNCATE TABLE [Report].[OfferReport_AllTrans]

		INSERT INTO [Report].[OfferReport_AllTrans]
		SELECT	DataSource = st.DataSource
			,	RetailerID = st.RetailerID
			,	PartnerID = st.PartnerID
			,	MID = st.MID
			,	FanID = st.FanID
			,	CINID = st.CINID
			,	IsOnline = st.IsOnline
			,	Amount = st.Amount
			,	TranDate = st.TranDate
			,	TranscactionID = ROW_NUMBER() OVER (ORDER BY st.MatchID)
		FROM [Report].[OfferReport_SchemeTrans] st
		
		DECLARE @MaxTranID INT
		
		SELECT	@MaxTranID = COALESCE(MAX([TransactionID]), 0)
		FROM [Report].[OfferReport_AllTrans]

		INSERT INTO [Report].[OfferReport_AllTrans]
		SELECT	DataSource = mt.DataSource
			,	RetailerID = mt.RetailerID
			,	PartnerID = mt.PartnerID
			,	MID = mt.MID
			,	FanID = mt.FanID
			,	CINID = mt.CINID
			,	IsOnline = mt.IsOnline
			,	Amount = mt.Amount
			,	TranDate = mt.TranDate
			,	TranscactionID = ROW_NUMBER() OVER (ORDER BY mt.MatchID) + @MaxTranID
		FROM [Report].[OfferReport_MatchTrans] mt
		
		SELECT	@MaxTranID = COALESCE(MAX([TransactionID]), 0)
		FROM [Report].[OfferReport_AllTrans]
		
		INSERT INTO [Report].[OfferReport_AllTrans]
		SELECT	DataSource = ct.DataSource
			,	RetailerID = ct.RetailerID
			,	PartnerID = ct.PartnerID
			,	MID = ct.MID
			,	FanID = cu.FanID
			,	CINID = ct.CINID
			,	IsOnline = ct.IsOnline
			,	Amount = ct.Amount
			,	TranDate = ct.TranDate
			,	TranscactionID = ROW_NUMBER() OVER (ORDER BY ct.TranDate) + @MaxTranID
		FROM [Report].[OfferReport_ConsumerTransaction] ct
		INNER JOIN [Derived].[Customer] cu
			ON ct.CINID = cu.CINID
			AND cu.PublisherID IN (132, 138)
		WHERE ct.DataSource = 'Warehouse'
		
		SELECT	@MaxTranID = COALESCE(MAX([TransactionID]), 0)
		FROM [Report].[OfferReport_AllTrans]
		
		INSERT INTO [Report].[OfferReport_AllTrans]
		SELECT	DataSource = ct.DataSource
			,	RetailerID = ct.RetailerID
			,	PartnerID = ct.PartnerID
			,	MID = ct.MID
			,	FanID = cu.FanID
			,	CINID = ct.CINID
			,	IsOnline = ct.IsOnline
			,	Amount = ct.Amount
			,	TranDate = ct.TranDate
			,	TranscactionID = ROW_NUMBER() OVER (ORDER BY ct.TranDate) + @MaxTranID
		FROM [Report].[OfferReport_ConsumerTransaction] ct
		INNER JOIN [Derived].[Customer] cu
			ON ct.CINID = cu.CINID
			AND cu.PublisherType = 'nFI'
		WHERE ct.DataSource = 'Warehouse'
		
		SELECT	@MaxTranID = COALESCE(MAX([TransactionID]), 0)
		FROM [Report].[OfferReport_AllTrans]
		
		INSERT INTO [Report].[OfferReport_AllTrans]
		SELECT	DataSource = ct.DataSource
			,	RetailerID = ct.RetailerID
			,	PartnerID = ct.PartnerID
			,	MID = ct.MID
			,	FanID = cu.FanID
			,	CINID = ct.CINID
			,	IsOnline = ct.IsOnline
			,	Amount = ct.Amount
			,	TranDate = ct.TranDate
			,	TranscactionID = ROW_NUMBER() OVER (ORDER BY ct.TranDate) + @MaxTranID
		FROM [Report].[OfferReport_ConsumerTransaction] ct
		INNER JOIN [Derived].[Customer] cu
			ON ct.CINID = cu.CINID
			AND cu.PublisherID IN (166)
		WHERE ct.DataSource = 'WH_Virgin'
		
		SELECT	@MaxTranID = COALESCE(MAX([TransactionID]), 0)
		FROM [Report].[OfferReport_AllTrans]
		
		INSERT INTO [Report].[OfferReport_AllTrans]
		SELECT	DataSource = ct.DataSource
			,	RetailerID = ct.RetailerID
			,	PartnerID = ct.PartnerID
			,	MID = ct.MID
			,	FanID = cu.FanID
			,	CINID = ct.CINID
			,	IsOnline = ct.IsOnline
			,	Amount = ct.Amount
			,	TranDate = ct.TranDate
			,	TranscactionID = ROW_NUMBER() OVER (ORDER BY ct.TranDate) + @MaxTranID
		FROM [Report].[OfferReport_ConsumerTransaction] ct
		INNER JOIN [Derived].[Customer] cu
			ON ct.CINID = cu.CINID
			AND cu.PublisherID IN (180)
		WHERE ct.DataSource = 'WH_Visa'
		
		SELECT	@MaxTranID = COALESCE(MAX([TransactionID]), 0)
		FROM [Report].[OfferReport_AllTrans]
		
		INSERT INTO [Report].[OfferReport_AllTrans]
		SELECT	DataSource = ct.DataSource
			,	RetailerID = ct.RetailerID
			,	PartnerID = ct.PartnerID
			,	MID = ct.MID
			,	FanID = fa.ID
			,	CINID = ct.CINID
			,	IsOnline = ct.IsOnline
			,	Amount = ct.Amount
			,	TranDate = ct.TranDate
			,	TranscactionID = ROW_NUMBER() OVER (ORDER BY ct.TranDate) + @MaxTranID
		FROM [Report].[OfferReport_ConsumerTransaction] ct
		INNER JOIN [Warehouse].[Relational].[CINList] cl
			ON ct.CINID = cl.CINID
		INNER JOIN [SLC_Report].[dbo].[Fan] fa
			ON cl.CIN = fa.SourceUID
			AND fa.ClubID IN (132, 138)
		WHERE NOT EXISTS (	SELECT 1
							FROM [Derived].[Customer] cu
							WHERE ct.CINID = cu.CINID
							AND fa.ClubID = cu.PublisherID)
		AND ct.DataSource = 'Warehouse'
					
	--CREATE CLUSTERED INDEX CIX_MatchID ON [Report].[OfferReport_MatchTrans] (MatchID)
	--CREATE NONCLUSTERED INDEX IX_FanID ON [Report].[OfferReport_MatchTrans] (FanID)
	--CREATE NONCLUSTERED INDEX IX_PartnerIDTrandDateAmount ON [Report].[OfferReport_MatchTrans] (PartnerID,[TranDate],[Amount]) INCLUDE (IsOnline)

END