CREATE TABLE [MIDI].[__CTLoad_MIDINarrativeCleanup_Archived] (
    [ID]                  INT          IDENTITY (1, 1) NOT NULL,
    [TextToReplace]       VARCHAR (15) NULL,
    [IsPrefixRemoved]     BIT          NULL,
    [HonourPrefixRemoval] BIT          NULL,
    [LiveRule]            BIT          NULL,
    [NarrativeNotLike]    VARCHAR (15) NULL
);

