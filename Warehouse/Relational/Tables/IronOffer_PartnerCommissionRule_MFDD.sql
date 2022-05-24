CREATE TABLE [Relational].[IronOffer_PartnerCommissionRule_MFDD] (
    [PCRID]                      INT IDENTITY (1, 1) NOT NULL,
    [IronOfferID]                INT NULL,
    [FixedPriceCashback_BelowSS] INT NULL,
    [RequiredMinimumBasketSize]  INT NULL,
    [FixedPriceCashback_AboveSS] INT NULL,
    CONSTRAINT [pk_PCRID] PRIMARY KEY CLUSTERED ([PCRID] ASC)
);

