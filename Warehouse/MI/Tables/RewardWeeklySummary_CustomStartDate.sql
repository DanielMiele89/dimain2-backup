CREATE TABLE [MI].[RewardWeeklySummary_CustomStartDate] (
    [PartnerID]       INT  NOT NULL,
    [CustomStartDate] DATE NULL,
    [StopDate]        DATE NULL,
    CONSTRAINT [PK_MI_RewardWeeklySummary_CustomStartDate] PRIMARY KEY CLUSTERED ([PartnerID] ASC)
);

