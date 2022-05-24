CREATE TABLE [Relational].[DriveTimePerPartner] (
    [FanID]            INT      NOT NULL,
    [PartnerID]        INT      NOT NULL,
    [RunDate]          DATETIME NULL,
    [DriveTimeGroupID] TINYINT  NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC, [PartnerID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
);

