CREATE TABLE [Relational].[Customers_ReducedFrequency_OriginalSelection] (
    [FanID]                  INT         NOT NULL,
    [CJS]                    CHAR (3)    NULL,
    [CustomerType]           VARCHAR (7) NOT NULL,
    [TestGroup]              VARCHAR (3) NOT NULL,
    [ClubCashPending]        SMALLMONEY  NULL,
    [ClubCashAvailable]      SMALLMONEY  NULL,
    [CurrentlyBeingExcluded] BIT         NULL,
    [DateLeftCJS]            DATE        NULL
);

