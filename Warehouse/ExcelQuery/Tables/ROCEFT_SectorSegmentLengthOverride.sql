CREATE TABLE [ExcelQuery].[ROCEFT_SectorSegmentLengthOverride] (
    [SectorName] VARCHAR (50) NULL,
    [SectorID]   INT          NOT NULL,
    [AcquireL]   INT          NULL,
    [LapserL]    INT          NULL,
    CONSTRAINT [pk_SectorID] PRIMARY KEY CLUSTERED ([SectorID] ASC)
);

