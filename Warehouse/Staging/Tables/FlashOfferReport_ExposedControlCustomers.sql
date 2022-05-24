CREATE TABLE [Staging].[FlashOfferReport_ExposedControlCustomers] (
    [GroupID]            INT NOT NULL,
    [FanID]              INT NOT NULL,
    [CINID]              INT NULL,
    [Exposed]            BIT NOT NULL,
    [IsWarehouse]        INT NULL,
    [ControlGroupTypeID] INT NULL
);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff]
    ON [Staging].[FlashOfferReport_ExposedControlCustomers]([Exposed] ASC, [IsWarehouse] ASC, [CINID] ASC, [ControlGroupTypeID] ASC, [GroupID] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [NIX_FlashOfferReport_ExposedControlCustomers]
    ON [Staging].[FlashOfferReport_ExposedControlCustomers]([IsWarehouse] ASC, [Exposed] ASC, [ControlGroupTypeID] ASC, [GroupID] ASC)
    INCLUDE([CINID]) WITH (FILLFACTOR = 75, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE UNIQUE CLUSTERED INDEX [UCX_FlashOfferReport_ExposedControlCustomers]
    ON [Staging].[FlashOfferReport_ExposedControlCustomers]([GroupID] ASC, [IsWarehouse] ASC, [FanID] ASC, [Exposed] ASC, [ControlGroupTypeID] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE);

