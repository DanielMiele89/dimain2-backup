CREATE TABLE [dbo].[SourceType] (
    [SourceTypeID]      SMALLINT      IDENTITY (1, 1) NOT NULL,
    [SourceTable]       VARCHAR (50)  NOT NULL,
    [DestinationTable]  VARCHAR (50)  NOT NULL,
    [SourceColumns]     VARCHAR (50)  NULL,
    [SourceDescription] VARCHAR (100) NULL,
    [SourceSystemID]    SMALLINT      NOT NULL,
    CONSTRAINT [pk_SourceType] PRIMARY KEY CLUSTERED ([SourceTypeID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [CHK_DestinationTable] CHECK ([DestinationTable] like '[A-Za-z]%.%'),
    CONSTRAINT [CHK_SourceName] CHECK ([SourceTable] like '[A-Za-z]%.%'),
    CONSTRAINT [FK_SourceType_SourceSystemID] FOREIGN KEY ([SourceSystemID]) REFERENCES [dbo].[SourceSystem] ([SourceSystemID]),
    CONSTRAINT [UQ_SourceLocation] UNIQUE NONCLUSTERED ([SourceTable] ASC, [DestinationTable] ASC, [SourceSystemID] ASC) WITH (FILLFACTOR = 90)
);

