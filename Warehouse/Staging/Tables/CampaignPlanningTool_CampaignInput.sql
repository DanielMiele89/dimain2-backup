CREATE TABLE [Staging].[CampaignPlanningTool_CampaignInput] (
    [PartnerID]         INT             NOT NULL,
    [PartnerName]       VARCHAR (150)   NOT NULL,
    [ClientServicesRef] VARCHAR (25)    NOT NULL,
    [CampaignName]      VARCHAR (150)   NULL,
    [CampaignType]      VARCHAR (25)    NULL,
    [MainObjective]     VARCHAR (50)    NULL,
    [Budget]            NUMERIC (32, 8) NULL,
    [MarketingSupport]  VARCHAR (20)    NULL,
    [EmailTesting]      BIT             NULL,
    [CustomerBaseID]    INT             NULL,
    [BirthdayType]      VARCHAR (50)    NULL,
    [ATL]               BIT             NULL,
    [RetailerType]      VARCHAR (40)    NULL,
    [ControlGroup_Size] DECIMAL (3, 2)  NULL,
    [Status_StartDate]  DATE            NULL,
    [Status_EndDate]    DATE            NULL,
    CONSTRAINT [pk_Campaign] PRIMARY KEY CLUSTERED ([PartnerID] ASC, [ClientServicesRef] ASC)
);

