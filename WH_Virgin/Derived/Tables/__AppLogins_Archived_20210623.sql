﻿CREATE TABLE [Derived].[__AppLogins_Archived_20210623] (
    [ID]          BIGINT        IDENTITY (1, 1) NOT NULL,
    [FanID]       INT           NOT NULL,
    [TrackTypeID] INT           NOT NULL,
    [TrackDate]   DATETIME      NOT NULL,
    [FanData]     VARCHAR (200) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [ucx_AL]
    ON [Derived].[__AppLogins_Archived_20210623]([ID] ASC);


GO
CREATE NONCLUSTERED INDEX [NIX]
    ON [Derived].[__AppLogins_Archived_20210623]([FanData] ASC)
    INCLUDE([ID], [FanID], [TrackTypeID], [TrackDate]);

