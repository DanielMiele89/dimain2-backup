CREATE TABLE [Relational].[IronOfferMember] (
    [IronOfferID] SMALLINT NULL,
    [FanID]       INT      NULL,
    [StartDate]   DATETIME NULL,
    [EndDate]     DATETIME NULL,
    [ImportDate]  DATETIME NULL
);


GO
CREATE CLUSTERED INDEX [IDX_FID]
    ON [Relational].[IronOfferMember]([FanID] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [IDX_IID]
    ON [Relational].[IronOfferMember]([IronOfferID] ASC, [FanID] ASC, [StartDate] ASC)
    INCLUDE([EndDate]) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE)
    ON [nFI_Indexes];


GO
DENY ALTER
    ON OBJECT::[Relational].[IronOfferMember] TO [OnCall]
    AS [dbo];


GO
DENY DELETE
    ON OBJECT::[Relational].[IronOfferMember] TO [OnCall]
    AS [dbo];

