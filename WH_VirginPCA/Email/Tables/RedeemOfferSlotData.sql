CREATE TABLE [Email].[RedeemOfferSlotData] (
    [FanID]                   INT  NOT NULL,
    [LionSendID]              INT  NOT NULL,
    [RedeemOfferID_Hero]      INT  NOT NULL,
    [RedeemOfferID_1]         INT  NOT NULL,
    [RedeemOfferID_2]         INT  NOT NULL,
    [RedeemOfferID_3]         INT  NOT NULL,
    [RedeemOfferID_4]         INT  NOT NULL,
    [RedeemOfferEndDate_Hero] DATE NULL,
    [RedeemOfferEndDate_1]    DATE NULL,
    [RedeemOfferEndDate_2]    DATE NULL,
    [RedeemOfferEndDate_3]    DATE NULL,
    [RedeemOfferEndDate_4]    DATE NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);

