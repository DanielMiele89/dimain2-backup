CREATE TABLE [Derived].[CustomerIDs] (
    [FanID]                BIGINT        IDENTITY (-1, -1) NOT NULL,
    [PublisherID]          INT           NULL,
    [PublisherID_RewardBI] INT           NULL,
    [CustomerID]           VARCHAR (100) NOT NULL,
    [CustomerIDTypeID]     TINYINT       NULL,
    [ImportDate]           DATETIME2 (7) NOT NULL,
    CONSTRAINT [PK_Derived_CustomerIDs] PRIMARY KEY CLUSTERED ([FanID] ASC)
);

