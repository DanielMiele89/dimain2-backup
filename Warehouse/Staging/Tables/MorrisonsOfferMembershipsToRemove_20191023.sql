CREATE TABLE [Staging].[MorrisonsOfferMembershipsToRemove_20191023] (
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


GO
CREATE CLUSTERED INDEX [CIX_All]
    ON [Staging].[MorrisonsOfferMembershipsToRemove_20191023]([IronOfferID] ASC, [StartDate] ASC, [CompositeID] ASC);

