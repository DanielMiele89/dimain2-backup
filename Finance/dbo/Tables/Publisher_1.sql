CREATE TABLE [dbo].[Publisher] (
    [PublisherID]     SMALLINT       NOT NULL,
    [PublisherName]   VARCHAR (100)  NOT NULL,
    [PublisherStatus] TINYINT        NOT NULL,
    [CreatedDateTime] DATETIME2 (7)  NOT NULL,
    [UpdatedDateTime] DATETIME2 (7)  NOT NULL,
    [MD5]             VARBINARY (16) NOT NULL,
    CONSTRAINT [PK_Publishers] PRIMARY KEY CLUSTERED ([PublisherID] ASC) WITH (FILLFACTOR = 90)
);

