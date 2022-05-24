CREATE TABLE [dbo].[removals] (
    [ID]          INT      NOT NULL,
    [CompositeID] BIGINT   NOT NULL,
    [IronOfferID] INT      NOT NULL,
    [StartDate]   DATETIME NOT NULL,
    [EndDate]     DATETIME NULL,
    [Date]        DATETIME NULL,
    [IsControl]   BIT      NULL
);

