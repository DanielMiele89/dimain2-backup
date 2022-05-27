CREATE TABLE [Relational].[DriveTimeMatrix_2021] (
    [FromSector]         VARCHAR (6) NOT NULL,
    [ToSector]           VARCHAR (6) NOT NULL,
    [DriveTimeMins]      FLOAT (53)  NULL,
    [DriveDistMiles]     FLOAT (53)  NULL,
    [PeakTime_Mins]      FLOAT (53)  NULL,
    [PeakDistance_Miles] FLOAT (53)  NULL
);

