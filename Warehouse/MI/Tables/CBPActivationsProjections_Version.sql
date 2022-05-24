CREATE TABLE [MI].[CBPActivationsProjections_Version] (
    [Version]     INT           NOT NULL,
    [ReleaseDate] DATE          NULL,
    [Description] VARCHAR (MAX) NULL,
    CONSTRAINT [PK_Ver] PRIMARY KEY CLUSTERED ([Version] ASC)
);

