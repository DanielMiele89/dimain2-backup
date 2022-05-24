CREATE TABLE [Segmentation].[ROC_Shopper_Segment_Partner_SettingsV2] (
    [ID]          INT      IDENTITY (1, 1) NOT NULL,
    [PartnerID]   INT      NOT NULL,
    [Acquire]     SMALLINT NOT NULL,
    [Acquire_Pct] INT      NOT NULL,
    [Lapsed]      SMALLINT NOT NULL,
    [StartDate]   DATE     NOT NULL,
    [EndDate]     DATE     NULL,
    [AutoRun]     BIT      NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

