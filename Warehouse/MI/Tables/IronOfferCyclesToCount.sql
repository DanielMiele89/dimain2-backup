CREATE TABLE [MI].[IronOfferCyclesToCount] (
    [ID]          INT      IDENTITY (1, 1) NOT NULL,
    [IronOfferID] INT      NOT NULL,
    [StartDate]   DATETIME NOT NULL,
    [EndDate]     DATETIME NOT NULL,
    CONSTRAINT [PK_MI_IronOfferCyclesToCount] PRIMARY KEY CLUSTERED ([ID] ASC)
);

