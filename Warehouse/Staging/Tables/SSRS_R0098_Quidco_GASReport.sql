CREATE TABLE [Staging].[SSRS_R0098_Quidco_GASReport] (
    [Reporting_Period] VARCHAR (13)   NOT NULL,
    [StartPeriod]      DATETIME       NULL,
    [EndPeriod]        DATETIME       NULL,
    [PartnerName]      NVARCHAR (100) NOT NULL,
    [Transactors]      INT            NULL,
    [Spenders]         INT            NULL,
    [Spends]           INT            NULL,
    [Refunds]          INT            NULL,
    [TotalSpend]       MONEY          NULL,
    [Commission]       MONEY          NULL,
    [GrossCommission]  MONEY          NULL,
    [NetCommission]    MONEY          NULL,
    [cashbackamount]   MONEY          NULL
);

