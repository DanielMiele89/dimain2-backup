CREATE TABLE [dbo].[SourceSystem_OLD] (
    [SourceSystemID]    INT           NOT NULL,
    [SourceName]        VARCHAR (50)  NOT NULL,
    [SourceDescription] VARCHAR (100) NULL,
    [SourceTypeID1Name] VARCHAR (100) NOT NULL,
    [SourceTypeID2Name] VARCHAR (100) NULL,
    CONSTRAINT [pk_SourceSystem_OLD] PRIMARY KEY CLUSTERED ([SourceSystemID] ASC)
);

