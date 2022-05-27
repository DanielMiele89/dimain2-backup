CREATE TABLE [iron].[OfferMemberAddition_24248_20211201] (
    [ID]          BIGINT   IDENTITY (1, 1) NOT NULL,
    [CompositeID] BIGINT   NOT NULL,
    [IronOfferID] INT      NOT NULL,
    [StartDate]   DATETIME NOT NULL,
    [EndDate]     DATETIME NULL,
    [Date]        DATETIME NULL,
    [IsControl]   BIT      NULL
);

