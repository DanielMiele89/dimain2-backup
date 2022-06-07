CREATE TABLE [dbo].[Redemptions] (
    [RedemptionID]       INT            IDENTITY (1, 1) NOT NULL,
    [CustomerID]         INT            NOT NULL,
    [PublisherID]        SMALLINT       NOT NULL,
    [RedemptionItemID]   INT            NOT NULL,
    [PaymentCardID]      INT            NOT NULL,
    [RedemptionValue]    DECIMAL (9, 2) NOT NULL,
    [RedemptionWorth]    DECIMAL (9, 2) NOT NULL,
    [RedemptionDate]     DATE           NOT NULL,
    [RedemptionDateTime] DATETIME2 (7)  NOT NULL,
    [isCancelled]        BIT            NOT NULL,
    [CancelledDate]      DATE           NULL,
    [SourceTypeID]       SMALLINT       NOT NULL,
    [SourceID]           VARCHAR (36)   NOT NULL,
    [CreatedDateTime]    DATETIME2 (7)  NOT NULL,
    [UpdatedDateTime]    DATETIME2 (7)  NOT NULL,
    [CancelledSourceID]  INT            NULL,
    CONSTRAINT [PK_Redemptions] PRIMARY KEY CLUSTERED ([RedemptionID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Redemptions_CustomerID] FOREIGN KEY ([CustomerID]) REFERENCES [dbo].[Customer] ([CustomerID]),
    CONSTRAINT [FK_Redemptions_PaymentCardID] FOREIGN KEY ([PaymentCardID]) REFERENCES [dbo].[PaymentCard] ([PaymentCardID]),
    CONSTRAINT [FK_Redemptions_PublisherID] FOREIGN KEY ([PublisherID]) REFERENCES [dbo].[Publisher] ([PublisherID]),
    CONSTRAINT [FK_Redemptions_RedemptionItemID] FOREIGN KEY ([RedemptionItemID]) REFERENCES [dbo].[RedemptionItem] ([RedemptionItemID]),
    CONSTRAINT [FK_Redemptions_SourceTypeID] FOREIGN KEY ([SourceTypeID]) REFERENCES [dbo].[SourceType] ([SourceTypeID])
);


GO
CREATE NONCLUSTERED INDEX [NIX_CustomerID_IsCancelled]
    ON [dbo].[Redemptions]([CustomerID] ASC, [isCancelled] ASC) WITH (FILLFACTOR = 90);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UNIX_Redemptions_Source]
    ON [dbo].[Redemptions]([SourceTypeID] ASC, [SourceID] ASC) WITH (FILLFACTOR = 90);

