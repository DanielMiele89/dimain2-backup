CREATE TABLE [Derived].[IronOfferMember] (
    [IronOfferMemberID] BIGINT   IDENTITY (1, 1) NOT NULL,
    [IronOfferID]       INT      NULL,
    [CompositeID]       BIGINT   NULL,
    [StartDate]         DATETIME NULL,
    [EndDate]           DATETIME NULL,
    [ImportDate]        DATETIME NULL,
    [ModifiedDate]      DATETIME DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_Relational_IronOfferMember] PRIMARY KEY CLUSTERED ([IronOfferMemberID] ASC) WITH (FILLFACTOR = 90)
);




GO
CREATE NONCLUSTERED INDEX [NCIX_CompModifiedDate]
    ON [Derived].[IronOfferMember]([CompositeID] ASC, [ModifiedDate] ASC)
    INCLUDE([IronOfferMemberID], [IronOfferID], [StartDate], [EndDate]);


GO
CREATE NONCLUSTERED INDEX [NCIX_ModifiedDate]
    ON [Derived].[IronOfferMember]([ModifiedDate] ASC)
    INCLUDE([IronOfferMemberID], [IronOfferID], [CompositeID], [StartDate], [EndDate]);


GO
CREATE NONCLUSTERED INDEX [IX_End_IncOfferCompStart]
    ON [Derived].[IronOfferMember]([EndDate] ASC)
    INCLUDE([IronOfferID], [CompositeID], [StartDate]);


GO
CREATE COLUMNSTORE INDEX [CSX_All]
    ON [Derived].[IronOfferMember]([IronOfferID], [CompositeID], [StartDate], [EndDate], [ImportDate]);


GO

CREATE TRIGGER [Derived].[Trigger_IronOfferMember_ModifiedDate]
ON [WH_Virgin].[Derived].[IronOfferMember]
AFTER UPDATE AS
	UPDATE WH_Virgin.Derived.IronOfferMember
	SET [WH_Virgin].[Derived].[IronOfferMember].[ModifiedDate] = GETDATE()
	WHERE [WH_Virgin].[Derived].[IronOfferMember].[IronOfferMemberID] IN (SELECT [WH_Virgin].[Derived].[IronOfferMember].[IronOfferMemberID] FROM inserted);