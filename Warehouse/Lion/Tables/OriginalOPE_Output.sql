CREATE TABLE [Lion].[OriginalOPE_Output] (
    [ID]          INT      IDENTITY (1, 1) NOT NULL,
    [LionSendID]  INT      NULL,
    [CompositeID] BIGINT   NOT NULL,
    [TypeID]      INT      NULL,
    [ItemRank]    INT      NULL,
    [ItemID]      INT      NULL,
    [Date]        DATETIME NULL
);


GO
CREATE CLUSTERED INDEX [CIX_LionSendComp]
    ON [Lion].[OriginalOPE_Output]([LionSendID] ASC, [CompositeID] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);

