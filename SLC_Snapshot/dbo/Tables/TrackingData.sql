CREATE TABLE [dbo].[TrackingData] (
    [fanid]          INT              NOT NULL,
    [tracktypeid]    INT              NOT NULL,
    [trackdate]      DATETIME         NOT NULL,
    [activitydata]   NVARCHAR (200)   NULL,
    [fandata]        NVARCHAR (200)   NULL,
    [TrackingDataID] UNIQUEIDENTIFIER NOT NULL,
    [LoginTypeID]    INT              NULL,
    CONSTRAINT [PK_TrackingDataID] PRIMARY KEY NONCLUSTERED ([TrackingDataID] ASC)
);


GO
CREATE CLUSTERED INDEX [cx_TrackingData]
    ON [dbo].[TrackingData]([tracktypeid] ASC, [fanid] ASC);

