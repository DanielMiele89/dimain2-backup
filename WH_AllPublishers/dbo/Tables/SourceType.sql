CREATE TABLE [dbo].[SourceType] (
    [SourceTypeID]   INT          NOT NULL,
    [SourceSystemID] INT          NOT NULL,
    [SourceType]     VARCHAR (30) NULL,
    [SourceTable]    VARCHAR (30) NULL,
    [SourceColumn]   VARCHAR (30) NULL,
    CONSTRAINT [PK_SourceType] PRIMARY KEY CLUSTERED ([SourceTypeID] ASC),
    CONSTRAINT [FK_SourceType_SourceSystemID] FOREIGN KEY ([SourceSystemID]) REFERENCES [dbo].[SourceSystem] ([SourceSystemID])
);

