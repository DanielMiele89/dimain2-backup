CREATE TABLE [Lion].[OfferMembershipsToRemove] (
    [ID]            INT           IDENTITY (1, 1) NOT NULL,
    [IronOfferID]   INT           NULL,
    [CompositeID]   BIGINT        NULL,
    [RemovalReason] VARCHAR (100) NULL
);


GO
CREATE CLUSTERED INDEX [CIX_OfferComp]
    ON [Lion].[OfferMembershipsToRemove]([IronOfferID] ASC, [CompositeID] ASC) WITH (FILLFACTOR = 90);

