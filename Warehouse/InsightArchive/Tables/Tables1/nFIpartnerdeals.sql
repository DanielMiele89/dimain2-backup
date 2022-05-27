CREATE TABLE [InsightArchive].[nFIpartnerdeals] (
    [ID]            INT           IDENTITY (1, 1) NOT NULL,
    [ClubID]        INT           NOT NULL,
    [PartnerName]   VARCHAR (150) NOT NULL,
    [PartnerID]     INT           NOT NULL,
    [brandid]       INT           NULL,
    [BrandName]     VARCHAR (150) NULL,
    [Introduced_By] VARCHAR (10)  NULL,
    [Managed_By]    VARCHAR (10)  NULL,
    [Current_Deal]  BIT           NULL,
    [StartDate]     VARCHAR (6)   NULL,
    [EndDate]       VARCHAR (6)   NULL,
    [Cashback]      FLOAT (53)    NULL,
    [Publisher]     FLOAT (53)    NULL,
    [Reward]        FLOAT (53)    NULL
);

