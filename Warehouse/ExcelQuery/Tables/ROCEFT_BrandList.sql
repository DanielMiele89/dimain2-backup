CREATE TABLE [ExcelQuery].[ROCEFT_BrandList] (
    [BrandID]   INT          NOT NULL,
    [BrandName] VARCHAR (50) NULL,
    [Core]      VARCHAR (2)  NULL,
    [Margin]    FLOAT (53)   NULL,
    [Override]  FLOAT (53)   NULL,
    [IsPartner] BIT          NULL,
    PRIMARY KEY CLUSTERED ([BrandID] ASC)
);

