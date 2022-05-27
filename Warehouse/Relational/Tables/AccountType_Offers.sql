CREATE TABLE [Relational].[AccountType_Offers] (
    [OfferID]               INT          NOT NULL,
    [BankID]                INT          NULL,
    [ProductCode]           VARCHAR (20) NULL,
    [ProductName]           VARCHAR (40) NULL,
    [OfferType]             BIT          NULL,
    [NumberOfTransRequired] INT          NULL,
    [RewardAmount]          MONEY        NULL,
    [MinValueOfTrans]       MONEY        NULL,
    CONSTRAINT [PK_AccountType_Offers] PRIMARY KEY CLUSTERED ([OfferID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [NCIX_AccountType_Offers]
    ON [Relational].[AccountType_Offers]([ProductCode] ASC);

