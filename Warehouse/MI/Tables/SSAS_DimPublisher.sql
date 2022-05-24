CREATE TABLE [MI].[SSAS_DimPublisher] (
    [PublisherID]   TINYINT      IDENTITY (1, 1) NOT NULL,
    [PublisherName] VARCHAR (50) NULL,
    CONSTRAINT [PK_MI_SSAS_DimPublisher] PRIMARY KEY CLUSTERED ([PublisherID] ASC)
);

