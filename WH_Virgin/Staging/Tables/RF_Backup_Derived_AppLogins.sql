CREATE TABLE [Staging].[RF_Backup_Derived_AppLogins] (
    [ID]          BIGINT        IDENTITY (1, 1) NOT NULL,
    [FanID]       INT           NOT NULL,
    [TrackTypeID] INT           NOT NULL,
    [TrackDate]   DATETIME      NOT NULL,
    [FanData]     VARCHAR (200) NULL
);

