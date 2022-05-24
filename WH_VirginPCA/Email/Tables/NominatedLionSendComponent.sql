CREATE TABLE [Email].[NominatedLionSendComponent] (
    [ID]          INT      IDENTITY (1, 1) NOT NULL,
    [LionSendID]  INT      NULL,
    [CompositeID] BIGINT   NOT NULL,
    [TypeID]      INT      NULL,
    [ItemRank]    INT      NULL,
    [ItemID]      INT      NULL,
    [StartDate]   DATETIME NULL,
    [EndDate]     DATETIME NULL,
    [Date]        DATETIME NULL,
    CONSTRAINT [PK_NominatedLionSendComponent] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [IUX_LSIDOfferCompRank] UNIQUE NONCLUSTERED ([LionSendID] ASC, [TypeID] ASC, [CompositeID] ASC, [ItemRank] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = ROW)
);


GO
CREATE NONCLUSTERED INDEX [IX_Item_IncCompRank]
    ON [Email].[NominatedLionSendComponent]([ItemID] ASC)
    INCLUDE([CompositeID], [ItemRank]);

