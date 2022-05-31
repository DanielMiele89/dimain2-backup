CREATE TABLE [PhillipB].[NWG_Primacy] (
    [FanID]                 INT    NULL,
    [Month]                 DATE   NULL,
    [Transactions]          INT    NULL,
    [TransactionsBehaviour] INT    NULL,
    [DirectDebitBehaviour]  INT    NULL,
    [DirectDebits]          INT    NULL,
    [Primacy]               INT    NULL,
    [TableKey]              BIGINT NOT NULL,
    PRIMARY KEY CLUSTERED ([TableKey] ASC) WITH (FILLFACTOR = 90)
);

