CREATE TABLE [dbo].[IronOfferMember] (
    [IronOfferID] INT      NOT NULL,
    [CompositeID] BIGINT   NOT NULL,
    [StartDate]   DATETIME NOT NULL,
    [EndDate]     DATETIME NULL,
    [ImportDate]  DATETIME NOT NULL,
    [IsControl]   BIT      NOT NULL,
    CONSTRAINT [PK_IronOfferMember] PRIMARY KEY CLUSTERED ([IronOfferID] ASC, [CompositeID] ASC, [StartDate] ASC) WITH (FILLFACTOR = 85)
);


GO
CREATE NONCLUSTERED INDEX [sn_Stuff01]
    ON [dbo].[IronOfferMember]([CompositeID] ASC, [ImportDate] ASC)
    INCLUDE([IronOfferID], [StartDate], [EndDate], [IsControl]) WITH (FILLFACTOR = 70)
    ON [SLC_REPL_Indexes];


GO
CREATE NONCLUSTERED INDEX [sn_Stuff_New]
    ON [dbo].[IronOfferMember]([StartDate] ASC, [CompositeID] ASC)
    INCLUDE([IronOfferID], [EndDate]) WITH (FILLFACTOR = 70)
    ON [SLC_REPL_Indexes];


GO
CREATE TRIGGER TriggerIOMUpdate on dbo.IronOfferMember
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO dbo.IronOfferMember_Changes (IronOfferID, CompositeID, StartDate, [Action])
	SELECT 
		i.IronOfferID, i.CompositeID, i.StartDate,
		[Action] = 'U'
	FROM inserted i 
END

GO

CREATE TRIGGER TriggerIOMInsert on dbo.IronOfferMember
AFTER INSERT
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO dbo.IronOfferMember_Changes (IronOfferID, CompositeID, StartDate, [Action])
	SELECT 
		i.IronOfferID, i.CompositeID, i.StartDate, 
		[Action] = 'I'
	FROM inserted i 
END

GO

CREATE TRIGGER [dbo].[TriggerIOMDelete] on [dbo].[IronOfferMember]
AFTER DELETE
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO dbo.IronOfferMember_Changes (IronOfferID, CompositeID, StartDate, [Action])
	SELECT 
		d.IronOfferID, d.CompositeID, d.StartDate, 
		[Action] = 'D'
	FROM deleted d 
END


GO
GRANT SELECT
    ON OBJECT::[dbo].[IronOfferMember] TO [PII_Removed]
    AS [dbo];

