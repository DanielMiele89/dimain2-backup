CREATE TABLE [APW].[PublisherExcludeWS] (
    [ID]          INT IDENTITY (1, 1) NOT NULL,
    [RetailerID]  INT NOT NULL,
    [PublisherID] INT NOT NULL,
    CONSTRAINT [PK_APW_PublisherExcludeWS] PRIMARY KEY CLUSTERED ([ID] ASC)
);

