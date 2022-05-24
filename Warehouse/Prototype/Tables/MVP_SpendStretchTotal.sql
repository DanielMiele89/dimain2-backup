CREATE TABLE [Prototype].[MVP_SpendStretchTotal] (
    [PKID]                 INT            IDENTITY (1, 1) NOT NULL,
    [RunDate]              DATE           NULL,
    [GroupName]            VARCHAR (50)   NULL,
    [BrandID]              INT            NULL,
    [ID]                   INT            NULL,
    [CumulativePercentage] DECIMAL (3, 2) NULL,
    [Boundary]             MONEY          NULL,
    PRIMARY KEY CLUSTERED ([PKID] ASC)
);

