CREATE TABLE [Derived].[Publishers] (
    [PublisherID]          INT           NOT NULL,
    [PublisherName]        VARCHAR (100) NOT NULL,
    [PublisherID_RewardBI] INT           NULL,
    CONSTRAINT [PK_Report_PublisherIDs] PRIMARY KEY CLUSTERED ([PublisherID] ASC)
);

