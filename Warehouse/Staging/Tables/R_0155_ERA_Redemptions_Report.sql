CREATE TABLE [Staging].[R_0155_ERA_Redemptions_Report] (
    [ReportDate]            DATETIME       NULL,
    [RedeemID]              INT            NOT NULL,
    [Red_Description]       NVARCHAR (100) NULL,
    [PartnerID]             INT            NULL,
    [PartnerName]           VARCHAR (100)  NULL,
    [WarningStockThreshold] INT            NULL,
    [StartDate]             DATETIME       NULL,
    [EndDate]               DATETIME       NULL,
    [Redemptions]           INT            NULL,
    [RowNumber]             BIGINT         NULL,
    [Average]               REAL           NULL,
    [Stock]                 INT            NULL,
    [YTD]                   INT            NULL
);

