CREATE TABLE [Relational].[DriveTimeMatrix_PreMar2022] (
    [FromSector]         VARCHAR (6) NOT NULL,
    [ToSector]           VARCHAR (6) NOT NULL,
    [DriveTimeMins]      FLOAT (53)  NULL,
    [DriveDistMiles]     FLOAT (53)  NULL,
    [PeakTime_Mins]      FLOAT (53)  NULL,
    [PeakDistance_Miles] FLOAT (53)  NULL,
    CONSTRAINT [pk_FromTo_PreMarch2022] PRIMARY KEY CLUSTERED ([FromSector] ASC, [ToSector] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
);


GO
CREATE NONCLUSTERED INDEX [IDX_MIN]
    ON [Relational].[DriveTimeMatrix_PreMar2022]([DriveTimeMins] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];

