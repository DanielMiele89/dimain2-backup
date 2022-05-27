CREATE TABLE [Staging].[DailyCashbackAwarded] (
    [ID]                         INT             IDENTITY (1, 1) NOT NULL,
    [Date]                       DATE            NULL,
    [DataSource]                 VARCHAR (25)    NULL,
    [CashbackAwarded]            DECIMAL (32, 2) NULL,
    [CashbackAwardedSinceKilian] DECIMAL (32, 2) NULL
);

