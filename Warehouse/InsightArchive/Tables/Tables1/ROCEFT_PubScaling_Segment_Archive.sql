CREATE TABLE [InsightArchive].[ROCEFT_PubScaling_Segment_Archive] (
    [BackupTime]     DATETIME        NOT NULL,
    [ClubID]         INT             NULL,
    [Clubname]       NVARCHAR (100)  NOT NULL,
    [ShopperSegment] VARCHAR (7)     NULL,
    [PubRRScaling]   NUMERIC (38, 6) NULL
);

