CREATE TABLE [MI].[CampaignPlanning_Trans] (
    [FanID]         INT              NOT NULL,
    [PartnerNameID] INT              NOT NULL,
    [Spenders1W]    NUMERIC (24, 12) NULL,
    [Value1W]       NUMERIC (33, 16) NULL,
    [Trans1W]       NUMERIC (24, 12) NULL,
    [Spenders2W]    NUMERIC (38, 6)  NULL,
    [Value2W]       NUMERIC (38, 6)  NULL,
    [Trans2W]       NUMERIC (38, 6)  NULL,
    [Spenders3W]    NUMERIC (2, 1)   NULL,
    [Value3W]       NUMERIC (22, 5)  NULL,
    [Trans3W]       NUMERIC (13, 1)  NULL,
    [Spenders4W]    NUMERIC (2, 1)   NULL,
    [Value4W]       NUMERIC (22, 5)  NULL,
    [Trans4W]       NUMERIC (13, 1)  NULL,
    PRIMARY KEY CLUSTERED ([PartnerNameID] ASC, [FanID] ASC)
);

