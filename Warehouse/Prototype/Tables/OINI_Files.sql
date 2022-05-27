CREATE TABLE [Prototype].[OINI_Files] (
    [FileID]       INT NULL,
    [AddedToTable] BIT NULL,
    [LoopID]       INT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_FileID]
    ON [Prototype].[OINI_Files]([FileID] ASC);

