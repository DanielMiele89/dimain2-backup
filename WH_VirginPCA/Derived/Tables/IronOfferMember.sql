CREATE TABLE [Derived].[IronOfferMember] (
    [IronOfferMemberID] BIGINT   IDENTITY (1, 1) NOT NULL,
    [IronOfferID]       INT      NULL,
    [CompositeID]       BIGINT   NULL,
    [StartDate]         DATETIME NULL,
    [EndDate]           DATETIME NULL,
    [ImportDate]        DATETIME NULL,
    [ModifiedDate]      DATETIME NULL,
    CONSTRAINT [PK_Relational_IronOfferMember] PRIMARY KEY CLUSTERED ([IronOfferMemberID] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IX_End_IncOfferCompStart]
    ON [Derived].[IronOfferMember]([EndDate] ASC)
    INCLUDE([IronOfferID], [CompositeID], [StartDate]);


GO
CREATE NONCLUSTERED INDEX [IX_OfferStart_IncCompEnd]
    ON [Derived].[IronOfferMember]([IronOfferID] ASC, [StartDate] ASC)
    INCLUDE([CompositeID], [EndDate]);


GO
CREATE NONCLUSTERED INDEX [NCIX_CompModifiedDate]
    ON [Derived].[IronOfferMember]([CompositeID] ASC, [ModifiedDate] ASC)
    INCLUDE([IronOfferMemberID], [IronOfferID], [StartDate], [EndDate]);


GO
CREATE NONCLUSTERED INDEX [NCIX_ModifiedDate]
    ON [Derived].[IronOfferMember]([ModifiedDate] ASC)
    INCLUDE([IronOfferMemberID], [IronOfferID], [CompositeID], [StartDate], [EndDate]);


GO
CREATE COLUMNSTORE INDEX [CSX_All]
    ON [Derived].[IronOfferMember]([IronOfferID], [CompositeID], [StartDate], [EndDate], [ImportDate]);


GO


CREATE TRIGGER [Derived].[Trigger_IronOfferMember_ModifiedDate]
ON [Derived].[IronOfferMember]
AFTER UPDATE AS
	UPDATE [WH_VirginPCA].[Derived].[IronOfferMember]
	SET ModifiedDate = GETDATE()
	WHERE IronOfferMemberID IN (SELECT IronOfferMemberID FROM inserted);
