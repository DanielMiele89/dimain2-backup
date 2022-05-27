CREATE TABLE [InsightArchive].[DWINGPolandSummary] (
    [WeekCommencing] DATE          NULL,
    [is_cnp]         BIT           NULL,
    [mcc]            INT           NULL,
    [mcg]            INT           NULL,
    [merchant_id]    INT           NULL,
    [merchant_name]  VARCHAR (400) NULL,
    [Spend]          FLOAT (53)    NULL,
    [NumTrx]         INT           NULL
);

