CREATE TABLE [Staging].[OPE_Offers_Weighted] (
    [IronOfferID]            INT    NULL,
    [PartnerID]              INT    NULL,
    [HTMID]                  INT    NULL,
    [Offer_Type]             INT    NULL,
    [Offer_Life]             INT    NULL,
    [Cashback_Rate]          INT    NULL,
    [Offer_Earn_Potential]   BIGINT NULL,
    [Offer_Exposure_History] INT    NULL,
    [Merchant_Tier]          INT    NULL,
    [Merchant_Type]          INT    NULL,
    [Forced]                 INT    NULL,
    [BaseOffer]              INT    NULL,
    [TotalScore]             BIGINT NULL,
    [RowNumber]              BIGINT NULL
);

