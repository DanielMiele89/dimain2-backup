CREATE TABLE [Relational].[IronOfferMember] (
    [IronOfferMemberID] BIGINT   IDENTITY (1, 1) NOT NULL,
    [IronOfferID]       INT      NULL,
    [CompositeID]       BIGINT   NULL,
    [StartDate]         DATETIME NULL,
    [EndDate]           DATETIME NULL,
    [ImportDate]        DATETIME NULL,
    CONSTRAINT [PK_Relational_IronOfferMember] PRIMARY KEY CLUSTERED ([IronOfferMemberID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [IX_OfferStartComp_End]
    ON [Relational].[IronOfferMember]([IronOfferID] ASC, [StartDate] DESC, [CompositeID] ASC)
    INCLUDE([EndDate]) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_IronOfferID_EndDate]
    ON [Relational].[IronOfferMember]([IronOfferID] ASC, [EndDate] ASC)
    INCLUDE([StartDate], [CompositeID]) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [IX_StartOfferComp_End]
    ON [Relational].[IronOfferMember]([StartDate] DESC, [IronOfferID] ASC, [CompositeID] ASC)
    INCLUDE([EndDate]) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];

