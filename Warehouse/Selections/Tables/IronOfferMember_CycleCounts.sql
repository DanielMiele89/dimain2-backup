CREATE TABLE [Selections].[IronOfferMember_CycleCounts] (
    [ID]            INT      IDENTITY (1, 1) NOT NULL,
    [IronOfferID]   INT      NOT NULL,
    [StartDate]     DATETIME NOT NULL,
    [EndDate]       DATETIME NOT NULL,
    [CustomerCount] INT      NOT NULL,
    CONSTRAINT [PK_IronOfferMember_CycleCounts] PRIMARY KEY CLUSTERED ([ID] ASC)
);

