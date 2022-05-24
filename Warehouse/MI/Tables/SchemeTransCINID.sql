CREATE TABLE [MI].[SchemeTransCINID] (
    [CINID]       INT    NOT NULL,
    [FanID]       INT    NOT NULL,
    [ClubID]      INT    NULL,
    [CompositeID] BIGINT NOT NULL,
    CONSTRAINT [PK_MI_SchemeTransCINID] PRIMARY KEY CLUSTERED ([CINID] ASC)
);

