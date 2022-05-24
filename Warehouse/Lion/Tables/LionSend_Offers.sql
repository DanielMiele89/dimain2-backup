CREATE TABLE [Lion].[LionSend_Offers] (
    [ID]            BIGINT IDENTITY (1, 1) NOT NULL,
    [LionSendID]    INT    NOT NULL,
    [EmailSendDate] DATE   NOT NULL,
    [CompositeID]   BIGINT NOT NULL,
    [FanID]         INT    NOT NULL,
    [TypeID]        INT    NOT NULL,
    [ItemID]        INT    NOT NULL,
    [OfferSlot]     INT    NOT NULL,
    CONSTRAINT [pk_ID] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 100, DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [IX_EmailTypeItem_IncComp]
    ON [Lion].[LionSend_Offers]([EmailSendDate] ASC, [TypeID] ASC, [ItemID] ASC)
    INCLUDE([CompositeID]) WITH (DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];

