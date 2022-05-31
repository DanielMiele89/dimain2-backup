CREATE TABLE [SamW].[MainBrandTotalUAESpenders] (
    [CINID]        INT          NOT NULL,
    [TranDate]     DATE         NOT NULL,
    [TypeDesc]     VARCHAR (50) NULL,
    [BrandName]    VARCHAR (50) NOT NULL,
    [Brand]        VARCHAR (50) NOT NULL,
    [NewBranding]  VARCHAR (50) NOT NULL,
    [CountryCode]  VARCHAR (2)  NOT NULL,
    [Spend]        MONEY        NULL,
    [Transactions] INT          NULL
);

