CREATE TABLE [MIDI].[GenericTrans_FilesProcessed] (
    [FileID]        INT      NOT NULL,
    [LoadDate]      DATETIME NOT NULL,
    [RowsImported]  INT      NULL,
    [ImportedDate]  DATETIME NULL,
    [RowsProcessed] INT      NULL,
    [ProcessedDate] DATETIME NULL,
    [RowsLoaded]    INT      NULL,
    [LoadedDate]    DATETIME NULL
);

