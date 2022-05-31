CREATE TABLE [Rory].[NominatedLionSendComponent_RedemptionOffers_20211201] (
    [ID]          INT      IDENTITY (1, 1) NOT NULL,
    [LionSendID]  INT      NULL,
    [CompositeID] BIGINT   NOT NULL,
    [TypeID]      INT      NULL,
    [ItemRank]    INT      NULL,
    [ItemID]      INT      NULL,
    [Date]        DATETIME NULL
);

