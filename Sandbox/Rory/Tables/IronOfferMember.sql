CREATE TABLE [Rory].[IronOfferMember] (
    [IronOfferMemberID] BIGINT   IDENTITY (1, 1) NOT NULL,
    [IronOfferID]       INT      NULL,
    [CompositeID]       BIGINT   NULL,
    [StartDate]         DATETIME NULL,
    [EndDate]           DATETIME NULL,
    [ImportDate]        DATETIME NULL
);

