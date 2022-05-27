CREATE TABLE [Staging].[DirectDebitResults] (
    [ID]                    INT          IDENTITY (1, 1) NOT NULL,
    [ReportDate]            DATE         NOT NULL,
    [RetailerID]            INT          NOT NULL,
    [PeriodType]            VARCHAR (50) NOT NULL,
    [StartDate]             DATE         NULL,
    [EndDate]               DATE         NULL,
    [IronOfferID]           VARCHAR (50) NOT NULL,
    [IsExposed]             BIT          NOT NULL,
    [CustomerGroup]         VARCHAR (50) NOT NULL,
    [DDRankByDateGroup]     VARCHAR (50) NOT NULL,
    [Cardholders]           INT          NULL,
    [DDCount]               INT          NULL,
    [UniqueDDSpenders]      INT          NULL,
    [DDSpend]               MONEY        NULL,
    [CustomerGroupMinSpend] MONEY        NULL,
    CONSTRAINT [PK_DirectDebitResults] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [NCIX1_DirectDebitResults]
    ON [Staging].[DirectDebitResults]([RetailerID] ASC, [PeriodType] ASC, [StartDate] ASC)
    INCLUDE([ReportDate], [EndDate]);

