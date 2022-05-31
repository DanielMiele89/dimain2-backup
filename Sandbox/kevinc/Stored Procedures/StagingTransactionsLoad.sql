CREATE PROC [kevinc].[StagingTransactionsLoad]
AS

	--IF OBJECT_ID('kevinc.StagingTransactions') IS NOT NULL
	--DROP TABLE kevinc.StagingTransactions;
	--CREATE TABLE kevinc.StagingTransactions(
	--		[FileID]				[int] NOT NULL,
	--		[RowNum]				[int] NOT NULL,
	--		[ConsumerCombinationID] [int] NOT NULL,
	--		[SecondaryCombinationID] [int] NULL,
	--		[BankID]				[tinyint] NOT NULL,
	--		[LocationID]			[int] NOT NULL,
	--		[CardholderPresentData] [tinyint] NOT NULL,
	--		[TranDate]				[date] NOT NULL,
	--		[CINID]					[int] NOT NULL,
	--		[Amount]				[money] NOT NULL,
	--		[IsRefund]				[bit] NOT NULL,
	--		[IsOnline]				[bit] NOT NULL,
	--		[InputModeID]			[tinyint] NOT NULL,
	--		[PostStatusID]			[tinyint] NOT NULL,
	--		[PaymentTypeID]			[tinyint] NOT NULL,
	--		[PartnerID]				INT NOT NULL
	--)
	--CREATE CLUSTERED INDEX CIX ON kevinc.StagingTransactions (CINID, PartnerID, TranDate)

	INSERT INTO kevinc.StagingTransactions([FileID], [RowNum], [ConsumerCombinationID], [SecondaryCombinationID], [BankID], [LocationID], [CardholderPresentData], [TranDate], [CINID], [Amount], [IsRefund], [IsOnline], [InputModeID], [PostStatusID], [PaymentTypeID],[PartnerID])
	SELECT [FileID], [RowNum], ct.[ConsumerCombinationID], [SecondaryCombinationID], [BankID], [LocationID], [CardholderPresentData], [TranDate], [CINID], [Amount], [IsRefund], [IsOnline], [InputModeID], [PostStatusID], [PaymentTypeID], pcc.PartnerID
	FROM Warehouse.Relational.ConsumerTransaction ct
	JOIN kevinc.StagingPartnerConsumerCombinations pcc on pcc.ConsumerCombinationID = ct.ConsumerCombinationID
	JOIN (	
				SELECT PartnerID, MIN(o.StartDate) AS StartDate, Max(o.EndDate) AS EndDate 
				FROM kevinc.StagingOffer o 
				GROUP BY PartnerID
		) o ON pcc.PartnerID = o.PartnerId 
	AND ct.TranDate BETWEEN o.StartDate AND o.EndDate 	
	--Replaced below with above...	
	--WHERE ct.TranDate BETWEEN '2020-12-31' and '2021-01-13'

