CREATE TABLE [Staging].[CTLoad_MIDINarrativeCleanup] (
    [ID]                  INT          IDENTITY (1, 1) NOT NULL,
    [TextToReplace]       VARCHAR (15) NULL,
    [IsPrefixRemoved]     BIT          NULL,
    [HonourPrefixRemoval] BIT          NULL,
    [LiveRule]            BIT          NULL,
    [NarrativeNotLike]    VARCHAR (15) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [ucx_ID]
    ON [Staging].[CTLoad_MIDINarrativeCleanup]([ID] ASC);

