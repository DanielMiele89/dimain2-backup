CREATE TABLE [dbo].[SourceSystem] (
    [SourceSystemID]          SMALLINT      NOT NULL,
    [SourceSystemName]        VARCHAR (50)  NOT NULL,
    [SourceSystemDescription] VARCHAR (100) NULL,
    CONSTRAINT [pk_SourceSystem] PRIMARY KEY CLUSTERED ([SourceSystemID] ASC) WITH (FILLFACTOR = 90)
);

