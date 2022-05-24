CREATE TABLE [ExcelQuery].[ROCEFT_SpendStretch] (
    [ID]              INT   IDENTITY (1, 1) NOT NULL,
    [BrandID]         INT   NULL,
    [Cumu_Percentage] REAL  NULL,
    [Boundary]        MONEY NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

