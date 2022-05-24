CREATE TABLE [InsightArchive].[InsightArchiveCheck] (
    [ID]         SMALLINT      IDENTITY (1, 1) NOT NULL,
    [TableName]  VARCHAR (200) NOT NULL,
    [CreatedBy]  VARCHAR (50)  NOT NULL,
    [ReviewDate] DATE          NULL,
    CONSTRAINT [PK_InsightArchive_InsightArchiveCheck] PRIMARY KEY CLUSTERED ([ID] ASC)
);

