CREATE TABLE [Lion].[IronOfferMember] (
    [IronOfferID] INT      NULL,
    [CompositeID] BIGINT   NULL,
    [StartDate]   DATETIME NULL,
    [EndDate]     DATETIME NULL,
    [PartnerID]   INT      NULL
);


GO
CREATE CLUSTERED INDEX [CIX_OfferComp]
    ON [Lion].[IronOfferMember]([PartnerID] ASC, [IronOfferID] ASC, [CompositeID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [IX_Comp]
    ON [Lion].[IronOfferMember]([CompositeID] ASC) WITH (FILLFACTOR = 90);

