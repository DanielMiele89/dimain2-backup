CREATE TABLE [SamW].[CaffeNeroStoreSpend] (
    [CINID]        INT            NOT NULL,
    [Age_Group]    VARCHAR (12)   NULL,
    [Region]       VARCHAR (30)   NULL,
    [Social_Class] NVARCHAR (255) NULL,
    [TranDate]     DATE           NOT NULL,
    [Amount]       MONEY          NOT NULL,
    [Store]        VARCHAR (6)    NULL
);

