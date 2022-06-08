CREATE TABLE [dbo].[SessionData] (
    [SessionID]              VARCHAR (32)     NOT NULL,
    [CompiledDefinition]     UNIQUEIDENTIFIER NULL,
    [SnapshotDataID]         UNIQUEIDENTIFIER NULL,
    [IsPermanentSnapshot]    BIT              NULL,
    [ReportPath]             NVARCHAR (464)   NULL,
    [Timeout]                INT              NOT NULL,
    [AutoRefreshSeconds]     INT              NULL,
    [Expiration]             DATETIME         NOT NULL,
    [ShowHideInfo]           IMAGE            NULL,
    [DataSourceInfo]         IMAGE            NULL,
    [OwnerID]                UNIQUEIDENTIFIER NOT NULL,
    [EffectiveParams]        NTEXT            NULL,
    [CreationTime]           DATETIME         NOT NULL,
    [HasInteractivity]       BIT              NULL,
    [SnapshotExpirationDate] DATETIME         NULL,
    [HistoryDate]            DATETIME         NULL,
    [PageHeight]             FLOAT (53)       NULL,
    [PageWidth]              FLOAT (53)       NULL,
    [TopMargin]              FLOAT (53)       NULL,
    [BottomMargin]           FLOAT (53)       NULL,
    [LeftMargin]             FLOAT (53)       NULL,
    [RightMargin]            FLOAT (53)       NULL,
    [AwaitingFirstExecution] BIT              NULL,
    [EditSessionID]          VARCHAR (32)     NULL,
    [DataSetInfo]            VARBINARY (MAX)  NULL,
    [SitePath]               NVARCHAR (440)   NULL,
    [SiteZone]               INT              DEFAULT ((0)) NOT NULL,
    [ReportDefinitionPath]   NVARCHAR (464)   NULL
);





GO
EXECUTE sp_tableoption @TableNamePattern = N'[dbo].[SessionData]', @OptionName = N'text in row', @OptionValue = N'256';


GO
CREATE UNIQUE CLUSTERED INDEX [IDX_SessionData]
    ON [dbo].[SessionData]([SessionID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SessionCleanup]
    ON [dbo].[SessionData]([Expiration] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_SessionSnapshotID]
    ON [dbo].[SessionData]([SnapshotDataID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_EditSessionID]
    ON [dbo].[SessionData]([EditSessionID] ASC);


GO
GRANT UPDATE
    ON OBJECT::[dbo].[SessionData] TO [RSExecRole]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[SessionData] TO [RSExecRole]
    AS [dbo];


GO
GRANT REFERENCES
    ON OBJECT::[dbo].[SessionData] TO [RSExecRole]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[dbo].[SessionData] TO [RSExecRole]
    AS [dbo];


GO
GRANT DELETE
    ON OBJECT::[dbo].[SessionData] TO [RSExecRole]
    AS [dbo];

