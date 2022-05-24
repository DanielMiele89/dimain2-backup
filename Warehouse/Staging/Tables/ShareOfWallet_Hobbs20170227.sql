CREATE TABLE [Staging].[ShareOfWallet_Hobbs20170227] (
    [CINID]            INT          NOT NULL,
    [Eligibility]      VARCHAR (12) NOT NULL,
    [PartnerSpend]     MONEY        NOT NULL,
    [CategorySpend]    MONEY        NOT NULL,
    [PartnerShare_Pct] MONEY        NOT NULL,
    [Spend]            INT          NOT NULL,
    [Loyalty]          INT          NOT NULL,
    [CBCustomer]       BIT          NOT NULL,
    [Segment]          INT          NULL
);

