CREATE TABLE [InsightArchive].[QuidcoPartnerInformation] (
    [ID]            INT           IDENTITY (1, 1) NOT NULL,
    [PartnerName]   VARCHAR (150) NOT NULL,
    [PartnerID]     INT           NOT NULL,
    [BrandID]       INT           NULL,
    [BrandName]     VARCHAR (150) NULL,
    [Introduced_By] VARCHAR (10)  NULL,
    [Managed_By]    VARCHAR (10)  NULL,
    [Current_Deal]  BIT           NULL,
    [StartDate]     VARCHAR (6)   NULL,
    [EndDate]       VARCHAR (6)   NULL,
    [Cashback]      FLOAT (53)    NULL,
    [Quidco]        FLOAT (53)    NULL,
    [Reward]        FLOAT (53)    NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

