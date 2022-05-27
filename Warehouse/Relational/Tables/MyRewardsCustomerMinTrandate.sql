CREATE TABLE [Relational].[MyRewardsCustomerMinTrandate] (
    [CINID]       INT      NOT NULL,
    [BrandID]     SMALLINT NOT NULL,
    [TranCount]   INT      NULL,
    [MinTranDate] DATE     NULL,
    [MaxTranDate] DATE     NULL
);


GO
CREATE CLUSTERED INDEX [cx_CINID_BrandID]
    ON [Relational].[MyRewardsCustomerMinTrandate]([CINID] ASC, [BrandID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);

