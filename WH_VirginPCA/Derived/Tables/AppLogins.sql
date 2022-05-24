CREATE TABLE [Derived].[AppLogins] (
    [ID]          BIGINT        IDENTITY (1, 1) NOT NULL,
    [FanID]       INT           NOT NULL,
    [TrackTypeID] INT           NOT NULL,
    [TrackDate]   DATETIME2 (7) NOT NULL,
    [LoginInfoID] INT           NULL,
    [FanData]     VARCHAR (300) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [ucx_AL]
    ON [Derived].[AppLogins]([ID] ASC);


GO
CREATE NONCLUSTERED INDEX [NIX]
    ON [Derived].[AppLogins]([LoginInfoID] ASC)
    INCLUDE([ID], [FanID], [TrackTypeID], [TrackDate]);

