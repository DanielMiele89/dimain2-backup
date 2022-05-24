CREATE TABLE [Relational].[Partner_NonCoreBaseOffer] (
    [PartnerID]    INT      NOT NULL,
    [IronOfferID]  INT      NOT NULL,
    [StartDate]    DATETIME NULL,
    [EndDate]      DATETIME NULL,
    [CashbackRate] REAL     NULL,
    PRIMARY KEY CLUSTERED ([PartnerID] ASC, [IronOfferID] ASC)
);

