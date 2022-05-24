CREATE TABLE [Relational].[IronOfferMember_Archive] (
    [IronOfferMemberID] BIGINT   NOT NULL,
    [IronOfferID]       INT      NULL,
    [CompositeID]       BIGINT   NULL,
    [StartDate]         DATETIME NULL,
    [EndDate]           DATETIME NULL,
    [ImportDate]        DATETIME NULL
);


GO
CREATE CLUSTERED INDEX [ix_IronOfferMemberID]
    ON [Relational].[IronOfferMember_Archive]([IronOfferMemberID] ASC) WITH (FILLFACTOR = 75, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [IX_IronOffer_Inc_CompDates]
    ON [Relational].[IronOfferMember_Archive]([IronOfferID] ASC)
    INCLUDE([CompositeID], [StartDate], [EndDate]) WITH (DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE COLUMNSTORE INDEX [CSX_IronOfferMember_All]
    ON [Relational].[IronOfferMember_Archive]([IronOfferID], [CompositeID], [StartDate], [EndDate], [ImportDate])
    ON [Warehouse_Columnstores];

