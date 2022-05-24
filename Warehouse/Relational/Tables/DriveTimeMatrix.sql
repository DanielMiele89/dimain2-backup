CREATE TABLE [Relational].[DriveTimeMatrix] (
    [FromSector]         VARCHAR (6) NOT NULL,
    [ToSector]           VARCHAR (6) NOT NULL,
    [DriveTimeMins]      FLOAT (53)  NULL,
    [DriveDistMiles]     FLOAT (53)  NULL,
    [PeakTime_Mins]      FLOAT (53)  NULL,
    [PeakDistance_Miles] FLOAT (53)  NULL,
    CONSTRAINT [pk_FromTo] PRIMARY KEY CLUSTERED ([FromSector] ASC, [ToSector] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [IDX_MIN]
    ON [Relational].[DriveTimeMatrix]([DriveTimeMins] ASC) WITH (FILLFACTOR = 90);

