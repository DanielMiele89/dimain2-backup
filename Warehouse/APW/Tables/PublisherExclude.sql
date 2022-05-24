CREATE TABLE [APW].[PublisherExclude] (
    [ID]          INT  NOT NULL,
    [RetailerID]  INT  NOT NULL,
    [PublisherID] INT  NOT NULL,
    [StartDate]   DATE NOT NULL,
    [EndDate]     DATE NOT NULL,
    CONSTRAINT [PK_APW_PublisherExclude] PRIMARY KEY CLUSTERED ([ID] ASC)
);

