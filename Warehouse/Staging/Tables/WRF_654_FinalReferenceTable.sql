CREATE TABLE [Staging].[WRF_654_FinalReferenceTable] (
    [FRT_ID]         INT           IDENTITY (1, 1) NOT NULL,
    [FanID]          INT           NOT NULL,
    [Gender]         CHAR (1)      NULL,
    [AgeGroup]       VARCHAR (100) NULL,
    [CAMEO_CODE_GRP] VARCHAR (200) NULL,
    [PartnerID]      INT           NOT NULL,
    [DriveTimeBand]  VARCHAR (50)  NULL,
    PRIMARY KEY CLUSTERED ([FRT_ID] ASC) WITH (FILLFACTOR = 100, DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [IDX_FanID]
    ON [Staging].[WRF_654_FinalReferenceTable]([FanID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [IDX_DriveTimeBand]
    ON [Staging].[WRF_654_FinalReferenceTable]([DriveTimeBand] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [IDX_Gender]
    ON [Staging].[WRF_654_FinalReferenceTable]([Gender] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [IDX_PartnerID]
    ON [Staging].[WRF_654_FinalReferenceTable]([PartnerID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];

