CREATE TABLE [dbo].[Customer_OLD] (
    [CustomerID]        INT           NOT NULL,
    [PublisherID]       SMALLINT      NOT NULL,
    [CustomerStatusID]  SMALLINT      NOT NULL,
    [CashBackPending]   SMALLMONEY    NOT NULL,
    [CashBackAvailable] SMALLMONEY    NOT NULL,
    [CreatedDateTime]   DATETIME2 (7) NOT NULL,
    [UpdatedDateTime]   DATETIME2 (7) NULL,
    [ActivatedDate]     DATE          NULL,
    [DeactivatedDate]   DATE          NULL,
    [DeactivatedBandID] SMALLINT      NULL,
    CONSTRAINT [PK_Customer_OLD] PRIMARY KEY CLUSTERED ([CustomerID] ASC) WITH (FILLFACTOR = 95),
    CONSTRAINT [FK_Customer_CustomerStatus_OLD] FOREIGN KEY ([CustomerStatusID]) REFERENCES [dbo].[CustomerStatus_OLD] ([CustomerStatusID]),
    CONSTRAINT [FK_Customer_PublisherID_OLD] FOREIGN KEY ([PublisherID]) REFERENCES [dbo].[Publisher_OLD] ([PublisherID])
);

