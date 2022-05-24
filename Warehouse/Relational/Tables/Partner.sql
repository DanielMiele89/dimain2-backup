CREATE TABLE [Relational].[Partner] (
    [SequenceNumber]    SMALLINT      NULL,
    [PartnerID]         INT           NOT NULL,
    [PartnerName]       VARCHAR (100) NULL,
    [BrandID]           INT           NULL,
    [BrandName]         VARCHAR (100) NULL,
    [CurrentlyActive]   BIT           DEFAULT ((0)) NULL,
    [AccountManager]    VARCHAR (20)  NULL,
    [TransactionTypeID] INT           NULL,
    PRIMARY KEY CLUSTERED ([PartnerID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [I_Partner_BrandID]
    ON [Relational].[Partner]([BrandID] ASC);

