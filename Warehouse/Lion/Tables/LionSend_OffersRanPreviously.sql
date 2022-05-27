CREATE TABLE [Lion].[LionSend_OffersRanPreviously] (
    [ItemID] INT NOT NULL,
    [TypeID] INT NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_All]
    ON [Lion].[LionSend_OffersRanPreviously]([TypeID] ASC, [ItemID] ASC);

