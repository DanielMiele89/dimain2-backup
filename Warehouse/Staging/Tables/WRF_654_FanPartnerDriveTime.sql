CREATE TABLE [Staging].[WRF_654_FanPartnerDriveTime] (
    [FPDT_ID]       INT             IDENTITY (1, 1) NOT NULL,
    [FanID]         INT             NOT NULL,
    [PartnerID]     INT             NOT NULL,
    [Nearest_Store] NUMERIC (32, 2) NULL,
    [DriveTimeBand] VARCHAR (50)    NULL,
    PRIMARY KEY CLUSTERED ([FPDT_ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_PartnerID]
    ON [Staging].[WRF_654_FanPartnerDriveTime]([PartnerID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_Fan]
    ON [Staging].[WRF_654_FanPartnerDriveTime]([FanID] ASC);

