CREATE TABLE [InsightArchive].[Warehouse.InsightArchive.CBP_DirectDebit_EON_ForecastingData] (
    [index]                    BIGINT        NULL,
    [SourceUID]                FLOAT (53)    NULL,
    [CINID]                    BIGINT        NULL,
    [First_DirectDebitDate]    VARCHAR (MAX) NULL,
    [First_DirectDebitAmount]  FLOAT (53)    NULL,
    [Second_DirectDebitDate]   VARCHAR (MAX) NULL,
    [Second_DirectDebitAmount] FLOAT (53)    NULL,
    [Row_Num]                  BIGINT        NULL
);


GO
CREATE NONCLUSTERED INDEX [ix_InsightArchive_Warehouse.InsightArchive.CBP_DirectDebit_EON_ForecastingData_index]
    ON [InsightArchive].[Warehouse.InsightArchive.CBP_DirectDebit_EON_ForecastingData]([index] ASC);

