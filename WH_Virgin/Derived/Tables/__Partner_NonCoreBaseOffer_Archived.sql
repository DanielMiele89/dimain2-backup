CREATE TABLE [Derived].[__Partner_NonCoreBaseOffer_Archived] (
    [PartnerID]    INT      NOT NULL,
    [IronOfferID]  INT      NOT NULL,
    [StartDate]    DATETIME NULL,
    [EndDate]      DATETIME NULL,
    [CashbackRate] REAL     NULL,
    PRIMARY KEY CLUSTERED ([PartnerID] ASC, [IronOfferID] ASC)
);

