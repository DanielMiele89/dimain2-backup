CREATE TABLE [dbo].[IronOfferAdSpace] (
    [ID]          INT IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [Weight]      INT NULL,
    [TakeOver]    BIT NULL,
    [IronOfferID] INT NOT NULL,
    [AdSpaceID]   INT NOT NULL,
    CONSTRAINT [PK_IronOfferAdSpace] PRIMARY KEY CLUSTERED ([ID] ASC)
);

