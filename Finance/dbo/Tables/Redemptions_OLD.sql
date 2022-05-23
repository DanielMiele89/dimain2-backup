CREATE TABLE [dbo].[Redemptions_OLD] (
    [RedemptionID]      INT           IDENTITY (1, 1) NOT NULL,
    [SourceID]          INT           NOT NULL,
    [SourceSystemID]    INT           NOT NULL,
    [CustomerID]        INT           NOT NULL,
    [RedeemOfferID]     INT           NOT NULL,
    [RedemptionValue]   MONEY         NOT NULL,
    [RedemptionWorth]   MONEY         NOT NULL,
    [RedemptionDate]    DATE          NOT NULL,
    [isCancelled]       BIT           NOT NULL,
    [CancelledDate]     DATE          NULL,
    [CreatedDateTime]   DATETIME2 (7) NOT NULL,
    [UpdatedDateTime]   DATETIME2 (7) NOT NULL,
    [CancelledSourceID] INT           NULL,
    CONSTRAINT [PK_Redemptions_OLD] PRIMARY KEY CLUSTERED ([RedemptionID] ASC),
    CONSTRAINT [FK_Redemptions_CustomerID_OLD] FOREIGN KEY ([CustomerID]) REFERENCES [dbo].[Customer_OLD] ([CustomerID]),
    CONSTRAINT [FK_Redemptions_RedeemOfferID_OLD] FOREIGN KEY ([RedeemOfferID]) REFERENCES [dbo].[RedeemOffer_OLD] ([RedeemOfferID]),
    CONSTRAINT [FK_Redemptions_SourceSystemID_OLD] FOREIGN KEY ([SourceSystemID]) REFERENCES [dbo].[SourceSystem_OLD] ([SourceSystemID])
);


GO
CREATE NONCLUSTERED INDEX [NIX_CustomerID]
    ON [dbo].[Redemptions_OLD]([CustomerID] ASC, [isCancelled] ASC);

