CREATE TABLE [Michael].[VirginWireframeSectorEarningsAll] (
    [ID]                     INT           IDENTITY (1, 1) NOT NULL,
    [CalculationDate]        DATE          NULL,
    [PeriodType]             VARCHAR (50)  NOT NULL,
    [StartDate]              DATE          NOT NULL,
    [EndDate]                DATE          NOT NULL,
    [PublisherID]            INT           NULL,
    [PublisherName]          VARCHAR (50)  NULL,
    [AccountType]            VARCHAR (50)  NULL,
    [Sector]                 VARCHAR (100) NULL,
    [Region]                 VARCHAR (30)  NULL,
    [QualifyingSpend]        MONEY         NULL,
    [QualifyingTransactions] INT           NULL,
    [AllSpend]               MONEY         NULL,
    [AllTransactions]        INT           NULL,
    CONSTRAINT [PK_SectorEarningsAll] PRIMARY KEY CLUSTERED ([ID] ASC)
);

