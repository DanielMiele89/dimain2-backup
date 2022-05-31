CREATE TABLE [tasfia].[PalaceSkateboards_ATV] (
    [BrandName]   VARCHAR (50) NOT NULL,
    [CreditDebit] TINYINT      NOT NULL,
    [IsOnline]    BIT          NOT NULL,
    [PrePost]     VARCHAR (4)  NOT NULL,
    [Spend]       MONEY        NULL,
    [Customer]    INT          NULL,
    [SPS]         MONEY        NULL,
    [ATF]         INT          NULL,
    [ATV]         MONEY        NULL
);

