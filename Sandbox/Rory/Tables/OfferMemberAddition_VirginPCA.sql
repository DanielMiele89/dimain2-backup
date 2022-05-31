CREATE TABLE [Rory].[OfferMemberAddition_VirginPCA] (
    [ID]          BIGINT   IDENTITY (1, 1) NOT NULL,
    [CompositeID] BIGINT   NOT NULL,
    [IronOfferID] INT      NOT NULL,
    [StartDate]   DATETIME NOT NULL,
    [EndDate]     DATETIME NULL,
    [AddedDate]   DATETIME NULL
);

