CREATE TABLE [Prototype].[ROCLITE_TEST] (
    [SegmentationDate] DATE NULL,
    [CINID]            INT  NULL
);


GO
CREATE NONCLUSTERED INDEX [nix_SegmentationDate__CINID]
    ON [Prototype].[ROCLITE_TEST]([SegmentationDate] ASC)
    INCLUDE([CINID]);


GO
CREATE CLUSTERED INDEX [cix_CINID]
    ON [Prototype].[ROCLITE_TEST]([CINID] ASC);

