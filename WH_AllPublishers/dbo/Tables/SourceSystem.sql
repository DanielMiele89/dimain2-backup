CREATE TABLE [dbo].[SourceSystem] (
    [SourceSystemID]          INT           NOT NULL,
    [SourceSystemName]        VARCHAR (30)  NOT NULL,
    [SourceSystemDescription] VARCHAR (100) NULL,
    CONSTRAINT [PK_SourceSystem] PRIMARY KEY CLUSTERED ([SourceSystemID] ASC)
);

