CREATE TABLE [Derived].[Publisher] (
    [ID]                    INT           IDENTITY (1, 1) NOT NULL,
    [PublisherID]           INT           NOT NULL,
    [PublisherName]         VARCHAR (100) NOT NULL,
    [PublisherNickname]     VARCHAR (50)  NULL,
    [PublisherAbbreviation] VARCHAR (12)  NOT NULL,
    [PublisherID_RewardBI]  INT           NULL,
    [PublisherType]         VARCHAR (25)  NULL,
    [LiveStatus]            INT           NULL,
    [StartDate]             DATE          NULL,
    [EndDate]               DATE          NULL,
    [AddedDate]             DATETIME2 (7) NOT NULL,
    [ModifiedDate]          DATETIME2 (7) NOT NULL,
    PRIMARY KEY CLUSTERED ([PublisherID] ASC)
);

