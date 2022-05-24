CREATE TABLE [Email].[NominatedLionSendComponent_20211220] (
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


GO
CREATE CLUSTERED INDEX [CIX_CompOffer]
    ON [Email].[NominatedLionSendComponent_20211220]([CompositeID] ASC, [ItemID] ASC);

