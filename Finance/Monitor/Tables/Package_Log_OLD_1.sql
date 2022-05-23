CREATE TABLE [Monitor].[Package_Log_OLD] (
    [ID]               INT              IDENTITY (1, 1) NOT NULL,
    [RunID]            INT              NOT NULL,
    [PackageID]        UNIQUEIDENTIFIER NOT NULL,
    [SourceID]         UNIQUEIDENTIFIER NOT NULL,
    [SourceName]       VARCHAR (100)    NOT NULL,
    [RunStartDateTime] DATETIME         NOT NULL,
    [RunEndDateTime]   DATETIME         NULL,
    [isError]          BIT              NOT NULL,
    [SourceTypeID]     INT              NOT NULL,
    [RowCnt]           BIGINT           NULL,
    [isArchived]       BIT              DEFAULT ((0)) NOT NULL,
    [UserNotes]        VARCHAR (200)    NULL,
    CONSTRAINT [FK_Monitor_Package_Log_SourceTypeID_OLD] FOREIGN KEY ([SourceTypeID]) REFERENCES [Monitor].[Package_SourceType_OLD] ([SourceTypeID])
);


GO
CREATE UNIQUE CLUSTERED INDEX [ucix_monitor_package_log]
    ON [Monitor].[Package_Log_OLD]([RunID] ASC, [RunStartDateTime] ASC, [SourceID] ASC, [PackageID] ASC);


GO
CREATE NONCLUSTERED INDEX [ncix_monitor_package_log]
    ON [Monitor].[Package_Log_OLD]([RunStartDateTime] ASC, [RunEndDateTime] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Package Logging Table - holds the sources that were ran in a package along with their runtimes and any row counts, where source is an object is an SSIS package', @level0type = N'SCHEMA', @level0name = N'Monitor', @level1type = N'TABLE', @level1name = N'Package_Log_OLD';


GO
EXECUTE sp_addextendedproperty @name = N'Related_Process', @value = N'Client Data Pipeline', @level0type = N'SCHEMA', @level0name = N'Monitor', @level1type = N'TABLE', @level1name = N'Package_Log_OLD';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'IDENTITY column', @level0type = N'SCHEMA', @level0name = N'Monitor', @level1type = N'TABLE', @level1name = N'Package_Log_OLD', @level2type = N'COLUMN', @level2name = N'ID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'An ID that groups all sources that occur in a single run together', @level0type = N'SCHEMA', @level0name = N'Monitor', @level1type = N'TABLE', @level1name = N'Package_Log_OLD', @level2type = N'COLUMN', @level2name = N'RunID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The SSIS PackageID -- it is a SSIS System Variable', @level0type = N'SCHEMA', @level0name = N'Monitor', @level1type = N'TABLE', @level1name = N'Package_Log_OLD', @level2type = N'COLUMN', @level2name = N'PackageID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The SSIS SourceID -- it is a SSIS System Variable and represents any object in the control flow', @level0type = N'SCHEMA', @level0name = N'Monitor', @level1type = N'TABLE', @level1name = N'Package_Log_OLD', @level2type = N'COLUMN', @level2name = N'SourceID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The SSIS SourceName - it is a SSIS system Variable and represents the user defined name given in the control flow', @level0type = N'SCHEMA', @level0name = N'Monitor', @level1type = N'TABLE', @level1name = N'Package_Log_OLD', @level2type = N'COLUMN', @level2name = N'SourceName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The DateTime that the source started', @level0type = N'SCHEMA', @level0name = N'Monitor', @level1type = N'TABLE', @level1name = N'Package_Log_OLD', @level2type = N'COLUMN', @level2name = N'RunStartDateTime';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The DateTime that the source ended', @level0type = N'SCHEMA', @level0name = N'Monitor', @level1type = N'TABLE', @level1name = N'Package_Log_OLD', @level2type = N'COLUMN', @level2name = N'RunEndDateTime';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Identifies whether a source had an error', @level0type = N'SCHEMA', @level0name = N'Monitor', @level1type = N'TABLE', @level1name = N'Package_Log_OLD', @level2type = N'COLUMN', @level2name = N'isError';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The ID that links to Package_SourceType', @level0type = N'SCHEMA', @level0name = N'Monitor', @level1type = N'TABLE', @level1name = N'Package_Log_OLD', @level2type = N'COLUMN', @level2name = N'SourceTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The number of rows moved, where applicable', @level0type = N'SCHEMA', @level0name = N'Monitor', @level1type = N'TABLE', @level1name = N'Package_Log_OLD', @level2type = N'COLUMN', @level2name = N'RowCnt';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Functionality to remove logs from the vw_PackageLog views', @level0type = N'SCHEMA', @level0name = N'Monitor', @level1type = N'TABLE', @level1name = N'Package_Log_OLD', @level2type = N'COLUMN', @level2name = N'isArchived';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'User defined notes to add to specific logs, otherwise NULL', @level0type = N'SCHEMA', @level0name = N'Monitor', @level1type = N'TABLE', @level1name = N'Package_Log_OLD', @level2type = N'COLUMN', @level2name = N'UserNotes';

