CREATE TABLE [SamW].[SweatyBettySalesPitch] (
    [Customers]          INT           NULL,
    [Transactions]       INT           NULL,
    [Spend]              MONEY         NULL,
    [Period]             VARCHAR (8)   NOT NULL,
    [BrandName]          VARCHAR (50)  NOT NULL,
    [CAMEO_CODE_GRP]     VARCHAR (151) NOT NULL,
    [Region]             VARCHAR (30)  NULL,
    [AgeCurrentBandText] VARCHAR (10)  NULL,
    [Gender]             CHAR (1)      NULL
);

