CREATE TABLE [Staging].[OfferReport_CTCustomers_20210310] (
    [GroupID]     INT NOT NULL,
    [FanID]       INT NOT NULL,
    [CINID]       INT NULL,
    [Exposed]     BIT NOT NULL,
    [isWarehouse] BIT NULL,
    [IsVirgin]    BIT NULL
)
WITH (DATA_COMPRESSION = ROW);

