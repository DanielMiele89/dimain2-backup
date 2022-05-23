CREATE TABLE [dbo].[Publisher_OLD] (
    [PublisherID]     SMALLINT      NOT NULL,
    [Name]            VARCHAR (100) NOT NULL,
    [Status]          TINYINT       NOT NULL,
    [CreatedDateTime] DATETIME2 (7) NOT NULL,
    [UpdatedDateTime] DATETIME2 (7) NULL,
    CONSTRAINT [PK_Publishers_OLD] PRIMARY KEY CLUSTERED ([PublisherID] ASC)
);

