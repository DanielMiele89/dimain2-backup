CREATE TABLE [InsightArchive].[OfferMembershpsToRemove_20200310] (
    [IronOfferID]                 INT      NOT NULL,
    [CompositeID]                 BIGINT   NOT NULL,
    [StartDate]                   DATETIME NOT NULL,
    [EndDate]                     DATETIME NULL,
    [ImportDate]                  DATETIME NOT NULL,
    [IsControl]                   BIT      NOT NULL,
    [AutoAddToNewRegistrants]     BIT      NULL,
    [AreEligibleMembersCommitted] BIT      NULL,
    [AreControlMembersCommitted]  BIT      NULL,
    [IsTriggerOffer]              BIT      NULL
);

