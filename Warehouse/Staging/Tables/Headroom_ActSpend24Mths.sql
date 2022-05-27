CREATE TABLE [Staging].[Headroom_ActSpend24Mths] (
    [CINID]         INT          NOT NULL,
    [Eligibility]   VARCHAR (12) NOT NULL,
    [PartnerSpend]  MONEY        NOT NULL,
    [CategorySpend] MONEY        NOT NULL
);

