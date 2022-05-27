CREATE TABLE [ExcelQuery].[MVP_ControlAdjustedSCD] (
    [ID]        INT  IDENTITY (1, 1) NOT NULL,
    [CINID]     INT  NULL,
    [StartDate] DATE NULL,
    [EndDate]   DATE NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [nix_ComboID]
    ON [ExcelQuery].[MVP_ControlAdjustedSCD]([CINID] ASC)
    INCLUDE([StartDate], [EndDate]) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);

