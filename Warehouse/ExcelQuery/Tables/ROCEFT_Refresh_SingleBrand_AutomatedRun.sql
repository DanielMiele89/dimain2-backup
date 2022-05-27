CREATE TABLE [ExcelQuery].[ROCEFT_Refresh_SingleBrand_AutomatedRun] (
    [ID]           INT      IDENTITY (1, 1) NOT NULL,
    [BrandID]      INT      NOT NULL,
    [PriorityFlag] BIT      CONSTRAINT [PriorityFlag] DEFAULT ((0)) NOT NULL,
    [RefreshDate]  DATETIME NULL
);

