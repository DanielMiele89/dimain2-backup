CREATE TABLE [InsightArchive].[VMCCBankFundedPOC_Control_WouldhaveIncentiveTransactions] (
    [ConsumerCombinationID] INT             NOT NULL,
    [TranDate]              DATETIME2 (0)   NOT NULL,
    [CINID]                 INT             NOT NULL,
    [Amount]                MONEY           NOT NULL,
    [OfferType]             VARCHAR (6)     NOT NULL,
    [Cashback]              NUMERIC (22, 6) NULL,
    [ControlID]             VARCHAR (107)   NOT NULL
);

