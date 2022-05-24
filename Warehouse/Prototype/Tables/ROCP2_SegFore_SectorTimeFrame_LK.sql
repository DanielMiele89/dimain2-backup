CREATE TABLE [Prototype].[ROCP2_SegFore_SectorTimeFrame_LK] (
    [SectorName]  VARCHAR (50) NULL,
    [SectorID]    SMALLINT     NOT NULL,
    [AcquireL]    SMALLINT     NULL,
    [LapserL]     SMALLINT     NULL,
    [Acquire_Pct] INT          NULL,
    CONSTRAINT [pk_SectorID] PRIMARY KEY CLUSTERED ([SectorID] ASC)
);

