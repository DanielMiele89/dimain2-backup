CREATE TABLE [SamW].[Forecasting] (
    [Spend]                     MONEY         NULL,
    [Transactions]              INT           NULL,
    [Customers]                 INT           NULL,
    [SELECTION]                 INT           NULL,
    [AwarenessLevel]            VARCHAR (10)  NULL,
    [CustomerSegmentOnTranDate] VARCHAR (7)   NOT NULL,
    [CycleStartDate]            DATE          NULL,
    [BrandName]                 VARCHAR (500) NULL
);


GO
GRANT ALTER
    ON OBJECT::[SamW].[Forecasting] TO [ExcelQuery_DataOps]
    AS [SamW];


GO
GRANT DELETE
    ON OBJECT::[SamW].[Forecasting] TO [ExcelQuery_DataOps]
    AS [SamW];


GO
GRANT INSERT
    ON OBJECT::[SamW].[Forecasting] TO [ExcelQuery_DataOps]
    AS [SamW];


GO
GRANT SELECT
    ON OBJECT::[SamW].[Forecasting] TO [ExcelQuery_DataOps]
    AS [SamW];


GO
GRANT UPDATE
    ON OBJECT::[SamW].[Forecasting] TO [ExcelQuery_DataOps]
    AS [SamW];


GO
GRANT VIEW DEFINITION
    ON OBJECT::[SamW].[Forecasting] TO [ExcelQuery_DataOps]
    AS [SamW];

