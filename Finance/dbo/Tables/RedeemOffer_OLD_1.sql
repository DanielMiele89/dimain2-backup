CREATE TABLE [dbo].[RedeemOffer_OLD] (
    [RedeemOfferID]     INT            NOT NULL,
    [FulfillmentTypeID] SMALLINT       NOT NULL,
    [RedemptionType]    VARCHAR (8)    NULL,
    [RedeemDescription] NVARCHAR (100) NULL,
    [SupplierID]        INT            NOT NULL,
    [PartnerID]         INT            NOT NULL,
    [TradeUpValue]      SMALLMONEY     NULL,
    [CreatedDateTime]   DATETIME2 (7)  NOT NULL,
    [UpdatedDateTime]   DATETIME2 (7)  NULL,
    CONSTRAINT [PK_RedeemOffer_OLD] PRIMARY KEY CLUSTERED ([RedeemOfferID] ASC),
    CONSTRAINT [FK_RedeemOffer_PartnerID_OLD] FOREIGN KEY ([PartnerID]) REFERENCES [dbo].[Partner_OLD] ([PartnerID])
);

