CREATE TABLE [MI].[ServerVolume] (
    [ID]           INT          IDENTITY (1, 1) NOT NULL,
    [ServerName]   VARCHAR (50) NOT NULL,
    [VolumeLetter] NVARCHAR (1) NOT NULL,
    [TotalMB]      BIGINT       NOT NULL,
    [AvailableMB]  BIGINT       NOT NULL,
    [VolumeDate]   DATE         CONSTRAINT [DF_MI_ServerVolume_VolumeDate] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_MI_ServerVolume] PRIMARY KEY CLUSTERED ([ID] ASC)
);

