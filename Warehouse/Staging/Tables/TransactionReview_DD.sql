CREATE TABLE [Staging].[TransactionReview_DD] (
    [BrandID]       INT          NOT NULL,
    [BrandName]     VARCHAR (50) NOT NULL,
    [OIN]           INT          NOT NULL,
    [Narrative_RBS] VARCHAR (50) NULL,
    [Narrative_VF]  VARCHAR (50) NULL,
    [TranDate]      DATE         NULL,
    [Amount]        MONEY        NULL,
    [BankAccountID] INT          NULL,
    [FanID]         INT          NULL
);

