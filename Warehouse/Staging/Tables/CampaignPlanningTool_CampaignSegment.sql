CREATE TABLE [Staging].[CampaignPlanningTool_CampaignSegment] (
    [ID]                    INT             IDENTITY (1, 1) NOT NULL,
    [ClientServicesRef]     VARCHAR (40)    NULL,
    [StartDate]             DATE            NULL,
    [EndDate]               DATE            NULL,
    [HTMID]                 TINYINT         NULL,
    [CompetitorShopper4wk]  BIT             NULL,
    [Homemover]             BIT             NULL,
    [Lapser]                BIT             NULL,
    [Student]               BIT             NULL,
    [AcquireMember]         BIT             NULL,
    [SuperSegmentID]        TINYINT         NULL,
    [Gender]                CHAR (1)        NULL,
    [MinAge]                INT             NULL,
    [MaxAge]                INT             NULL,
    [DriveTimeBand]         VARCHAR (50)    NULL,
    [CAMEO_CODE_GRP]        VARCHAR (200)   NULL,
    [SocialClass]           NVARCHAR (2)    NULL,
    [MinHeatMapScore]       INT             NULL,
    [MaxHeatMapScore]       INT             NULL,
    [BespokeTargeting]      INT             NULL,
    [QualifyingMids]        INT             NULL,
    [OfferRate]             NUMERIC (7, 4)  NULL,
    [SpendThreshold]        MONEY           NULL,
    [AB_Split]              NUMERIC (32, 2) DEFAULT ((1.00)) NOT NULL,
    [Uplift]                DECIMAL (5, 4)  NULL,
    [NonCoreBO_CSRef]       VARCHAR (15)    NULL,
    [ActiveRow]             BIT             NULL,
    [ForecastSubmittedDate] DATETIME        NULL,
    [Status_StartDate]      DATE            NULL,
    [Status_EndDate]        DATE            NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_NC]
    ON [Staging].[CampaignPlanningTool_CampaignSegment]([NonCoreBO_CSRef] ASC) WHERE ([NonCoreBO_CSRef] IS NOT NULL);


GO
CREATE NONCLUSTERED INDEX [IDX_MaxH]
    ON [Staging].[CampaignPlanningTool_CampaignSegment]([MaxHeatMapScore] ASC) WHERE ([MaxHeatMapScore] IS NOT NULL);


GO
CREATE NONCLUSTERED INDEX [IDX_MinH]
    ON [Staging].[CampaignPlanningTool_CampaignSegment]([MinHeatMapScore] ASC) WHERE ([MinHeatMapScore] IS NOT NULL);


GO
CREATE NONCLUSTERED INDEX [IDX_SSI]
    ON [Staging].[CampaignPlanningTool_CampaignSegment]([SuperSegmentID] ASC) WHERE ([SuperSegmentID] IS NOT NULL);


GO
CREATE NONCLUSTERED INDEX [IDX_Acq]
    ON [Staging].[CampaignPlanningTool_CampaignSegment]([AcquireMember] ASC) WHERE ([AcquireMember] IS NOT NULL);


GO
CREATE NONCLUSTERED INDEX [IDX_Laps]
    ON [Staging].[CampaignPlanningTool_CampaignSegment]([Lapser] ASC) WHERE ([Lapser] IS NOT NULL);


GO
CREATE NONCLUSTERED INDEX [IDX_HTMID]
    ON [Staging].[CampaignPlanningTool_CampaignSegment]([HTMID] ASC) WHERE ([HTMID] IS NOT NULL);


GO
CREATE NONCLUSTERED INDEX [IDX_EDate]
    ON [Staging].[CampaignPlanningTool_CampaignSegment]([EndDate] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_SDate]
    ON [Staging].[CampaignPlanningTool_CampaignSegment]([StartDate] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_ClientServicesRef]
    ON [Staging].[CampaignPlanningTool_CampaignSegment]([ClientServicesRef] ASC);

