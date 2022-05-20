CREATE TABLE [dbo].[IronOfferMember_Changes] (
    [IronOfferID] INT      NOT NULL,
    [CompositeID] BIGINT   NOT NULL,
    [StartDate]   DATETIME NOT NULL,
    [Action]      CHAR (1) NULL,
    [ActionDate]  DATETIME DEFAULT (getdate()) NULL
);


GO
CREATE CLUSTERED INDEX [ucx_IOM]
    ON [dbo].[IronOfferMember_Changes]([IronOfferID] ASC, [CompositeID] ASC, [StartDate] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff]
    ON [dbo].[IronOfferMember_Changes]([Action] ASC, [ActionDate] ASC)
    INCLUDE([IronOfferID], [CompositeID], [StartDate]);

