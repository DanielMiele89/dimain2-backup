CREATE TABLE [Derived].[__IronOffer_PartnerCommissionRule_MFDD_Archived] (
    [PCRID]                      INT IDENTITY (1, 1) NOT NULL,
    [IronOfferID]                INT NULL,
    [FixedPriceCashback_BelowSS] INT NULL,
    [RequiredMinimumBasketSize]  INT NULL,
    [FixedPriceCashback_AboveSS] INT NULL,
    CONSTRAINT [pk_PCRID] PRIMARY KEY CLUSTERED ([PCRID] ASC)
);

