CREATE TYPE [Reporting].[CB] AS TABLE (
    [CashbackPending]   DECIMAL (11, 2) NOT NULL,
    [CashbackAvailable] DECIMAL (11, 2) NOT NULL,
    [CashbackLTV]       DECIMAL (11, 2) NOT NULL,
    [isActive]          BIT             NOT NULL,
    [StartDate]         DATE            NOT NULL,
    [EndDate]           DATE            NOT NULL);

