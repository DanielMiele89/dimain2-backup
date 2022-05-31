CREATE TABLE [Rory].[NominatedLionSendComponent_20220310] (
    [ID]          INT      IDENTITY (1, 1) NOT NULL,
    [LionSendID]  INT      NULL,
    [CompositeID] BIGINT   NOT NULL,
    [TypeID]      INT      NULL,
    [ItemRank]    INT      NULL,
    [ItemID]      INT      NULL,
    [StartDate]   DATETIME NULL,
    [EndDate]     DATETIME NULL,
    [Date]        DATETIME NULL
);

