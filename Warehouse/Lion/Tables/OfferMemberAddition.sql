CREATE TABLE [Lion].[OfferMemberAddition] (
    [IronOfferID] INT      NULL,
    [CompositeID] BIGINT   NULL,
    [StartDate]   DATETIME NULL,
    [EndDate]     DATETIME NULL,
    [PartnerID]   INT      NULL
);


GO
CREATE CLUSTERED INDEX [CIX_OfferComp]
    ON [Lion].[OfferMemberAddition]([IronOfferID] ASC, [CompositeID] ASC) WITH (FILLFACTOR = 90);

