CREATE TABLE [Staging].[Headroom_ActInitialBase_OLD] (
    [RowNo] INT NULL,
    [CINID] INT NOT NULL
);


GO
CREATE CLUSTERED INDEX [ixc_CinID]
    ON [Staging].[Headroom_ActInitialBase_OLD]([CINID] ASC);

