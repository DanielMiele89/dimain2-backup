CREATE TABLE [Staging].[OfferReport_CTCustomers] (
    [PublisherID]           INT NULL,
    [GroupID]               INT NOT NULL,
    [FanID]                 INT NOT NULL,
    [CINID_Warehouse]       INT NULL,
    [CINID_Virgin]          INT NULL,
    [CINID_VirginPCA]       INT NULL,
    [CINID_VisaBarclaycard] INT NULL,
    [Exposed]               BIT NOT NULL,
    [IsWarehouse]           BIT NULL,
    [IsVirgin]              BIT NULL,
    [IsVirginPCA]           BIT NULL,
    [IsVisaBarclaycard]     BIT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [UCX_OfferReport_CTCustomers]
    ON [Staging].[OfferReport_CTCustomers]([Exposed] ASC, [PublisherID] ASC, [GroupID] ASC, [FanID] ASC, [IsWarehouse] ASC, [IsVirgin] ASC, [IsVirginPCA] ASC, [IsVisaBarclaycard] ASC) WITH (FILLFACTOR = 75);


GO
CREATE NONCLUSTERED INDEX [IX_CINWarehouseIronEx]
    ON [Staging].[OfferReport_CTCustomers]([CINID_Warehouse] ASC, [GroupID] ASC)
    INCLUDE([Exposed], [IsWarehouse]) WITH (FILLFACTOR = 75);

