CREATE TABLE [Relational].[DriveTimeMatrix_PreNov2019] (
    [FromSector]         VARCHAR (6) NOT NULL,
    [ToSector]           VARCHAR (6) NOT NULL,
    [DriveTimeMins]      FLOAT (53)  NULL,
    [DriveDistMiles]     FLOAT (53)  NULL,
    [PeakTime_Mins]      FLOAT (53)  NULL,
    [PeakDistance_Miles] FLOAT (53)  NULL,
    CONSTRAINT [pk_FromTo_PreNov2019] PRIMARY KEY CLUSTERED ([FromSector] ASC, [ToSector] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [IDX_MIN_PreNov2019]
    ON [Relational].[DriveTimeMatrix_PreNov2019]([DriveTimeMins] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];

