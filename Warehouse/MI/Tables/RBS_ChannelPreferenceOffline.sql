CREATE TABLE [MI].[RBS_ChannelPreferenceOffline] (
    [FanID]               INT     NOT NULL,
    [ChannelPreferenceID] TINYINT CONSTRAINT [DF_MI_RBS_ChannelPreferenceOffline_ChannelPreferenceID] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_MI_RBS_ChannelPreferenceOffline] PRIMARY KEY CLUSTERED ([FanID] ASC)
);

