CREATE TABLE [Ewan].[NWG_EngagementScore] (
    [CycleID]                   INT          NULL,
    [CycleEndDate]              DATE         NULL,
    [FanID]                     INT          NULL,
    [CINID]                     INT          NULL,
    [SourceUID]                 VARCHAR (20) NULL,
    [ProductHoldingGroupNumber] INT          NULL,
    [ProductHoldingGroupName]   VARCHAR (60) NULL,
    [OperationalSegmentLabel]   VARCHAR (3)  NULL,
    [OperationalSubSegmentID]   VARCHAR (3)  NULL,
    [OperationalSubSegmentName] VARCHAR (50) NULL,
    [MarketingPermission]       INT          NULL,
    [ValidEmailAddress]         INT          NULL,
    [MultipleProducts]          INT          NULL,
    [DDSetUp]                   INT          NULL,
    [CardUsage]                 INT          NULL,
    [OfferUsage]                INT          NULL,
    [EmailOpens]                INT          NULL,
    [Redemptions]               INT          NULL,
    [WebLogins]                 INT          NULL,
    [EngagementScore]           INT          NULL
);


GO
CREATE NONCLUSTERED INDEX [indx_cycle]
    ON [Ewan].[NWG_EngagementScore]([CycleID] ASC);


GO
CREATE NONCLUSTERED INDEX [indx_fans]
    ON [Ewan].[NWG_EngagementScore]([FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [indx_profile]
    ON [Ewan].[NWG_EngagementScore]([ProductHoldingGroupNumber] ASC);

