CREATE TABLE [InsightArchive].[AmazonRedemptionOfferRedeemIDs_Additions] (
    [RedeemID]     INT          NULL,
    [CompositeID]  BIGINT       NULL,
    [SDate]        INT          NULL,
    [EndDate]      INT          NULL,
    [Date]         DATETIME     NOT NULL,
    [Type]         VARCHAR (20) NOT NULL,
    [CustomerType] VARCHAR (15) NULL,
    [FanID]        INT          NULL
);

