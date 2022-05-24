CREATE TABLE [Email].[TriggerEmailType] (
    [ID]                      BIGINT        IDENTITY (1, 1) NOT NULL,
    [TriggerEmail]            VARCHAR (100) NULL,
    [CurrentlyLive]           BIT           NULL,
    [MarketableCustomersOnly] BIT           NULL
);

