CREATE TABLE [InsightArchive].[ROCP2_SegFore_FixedBase] (
    [CINID] INT NOT NULL
);


GO
CREATE CLUSTERED INDEX [IND_CIns]
    ON [InsightArchive].[ROCP2_SegFore_FixedBase]([CINID] ASC);

