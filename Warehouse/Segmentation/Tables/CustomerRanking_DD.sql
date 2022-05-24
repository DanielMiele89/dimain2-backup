CREATE TABLE [Segmentation].[CustomerRanking_DD] (
    [FanID]     INT NOT NULL,
    [PartnerID] INT NOT NULL,
    [Ranking]   INT NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC, [PartnerID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_DDCustRank_PartnerFan]
    ON [Segmentation].[CustomerRanking_DD]([PartnerID] ASC, [FanID] ASC)
    INCLUDE([Ranking]) WITH (FILLFACTOR = 80)
    ON [Warehouse_Indexes];


GO
ALTER INDEX [IX_DDCustRank_PartnerFan]
    ON [Segmentation].[CustomerRanking_DD] DISABLE;

