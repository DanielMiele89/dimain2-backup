CREATE TABLE [Segmentation].[CustomersWithCINs] (
    [FanID] INT NULL,
    [CINID] INT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_FanID]
    ON [Segmentation].[CustomersWithCINs]([FanID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE CLUSTERED INDEX [CIX_CINID]
    ON [Segmentation].[CustomersWithCINs]([CINID] ASC, [FanID] ASC) WITH (FILLFACTOR = 90);

