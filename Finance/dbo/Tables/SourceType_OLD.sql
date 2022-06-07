CREATE TABLE [dbo].[SourceType_OLD] (
    [SourceTypeID]      INT           NOT NULL,
    [SourceName]        VARCHAR (30)  NOT NULL,
    [SourceDescription] VARCHAR (100) NULL,
    [SourceSystemID]    INT           NOT NULL,
    CONSTRAINT [pk_SourceType_OLD] PRIMARY KEY CLUSTERED ([SourceTypeID] ASC),
    CONSTRAINT [FK_SourceType_SourceSystemID_OLD] FOREIGN KEY ([SourceSystemID]) REFERENCES [dbo].[SourceSystem_OLD] ([SourceSystemID])
);

