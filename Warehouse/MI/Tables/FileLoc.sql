CREATE TABLE [MI].[FileLoc] (
    [FileID]         INT     NOT NULL,
    [LocID]          TINYINT NOT NULL,
    [Processed]      BIT     CONSTRAINT [DF_MI_FileLoc_Processed] DEFAULT ((0)) NOT NULL,
    [MaxRows]        INT     NOT NULL,
    [AdditProcessed] BIT     NULL,
    PRIMARY KEY CLUSTERED ([FileID] ASC)
);

