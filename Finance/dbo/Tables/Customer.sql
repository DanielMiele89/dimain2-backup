CREATE TABLE [dbo].[Customer] (
    [CustomerID]        INT            IDENTITY (1, 1) NOT NULL,
    [PublisherID]       SMALLINT       NOT NULL,
    [isActive]          BIT            NOT NULL,
    [CashBackPending]   SMALLMONEY     NOT NULL,
    [CashBackAvailable] SMALLMONEY     NOT NULL,
    [ActivatedDate]     DATE           NULL,
    [DeactivatedDate]   DATE           NULL,
    [DeactivatedBandID] SMALLINT       NULL,
    [isCredit]          BIT            NULL,
    [isDebit]           BIT            NULL,
    [SourceTypeID]      SMALLINT       NOT NULL,
    [SourceID]          VARCHAR (36)   NOT NULL,
    [CreatedDateTime]   DATETIME2 (7)  NOT NULL,
    [UpdatedDateTime]   DATETIME2 (7)  NOT NULL,
    [MD5]               VARBINARY (16) NOT NULL,
    CONSTRAINT [PK_Customer] PRIMARY KEY CLUSTERED ([CustomerID] ASC) WITH (FILLFACTOR = 95),
    CONSTRAINT [FK_Customer_PublisherID] FOREIGN KEY ([PublisherID]) REFERENCES [dbo].[Publisher] ([PublisherID]),
    CONSTRAINT [FK_Customer_SourceTypeID] FOREIGN KEY ([SourceTypeID]) REFERENCES [dbo].[SourceType] ([SourceTypeID])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UNIX_Customer_Source]
    ON [dbo].[Customer]([SourceTypeID] ASC, [SourceID] ASC) WITH (FILLFACTOR = 90);

