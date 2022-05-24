CREATE TABLE [Prototype].[MVP_ControlAdjustedSCD] (
    [ID]        INT  IDENTITY (1, 1) NOT NULL,
    [CINID]     INT  NULL,
    [StartDate] DATE NULL,
    [EndDate]   DATE NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff2]
    ON [Prototype].[MVP_ControlAdjustedSCD]([StartDate] ASC, [EndDate] DESC)
    INCLUDE([CINID]) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff1]
    ON [Prototype].[MVP_ControlAdjustedSCD]([EndDate] ASC, [StartDate] ASC)
    INCLUDE([CINID]) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [nix_ComboIndex]
    ON [Prototype].[MVP_ControlAdjustedSCD]([StartDate] ASC, [EndDate] ASC)
    INCLUDE([CINID]) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [nix_ComboID]
    ON [Prototype].[MVP_ControlAdjustedSCD]([CINID] ASC)
    INCLUDE([StartDate], [EndDate]);

