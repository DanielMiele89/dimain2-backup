CREATE TABLE [Relational].[campaignhistory] (
    [ironoffercyclesid] INT NOT NULL,
    [fanid]             INT NOT NULL,
    PRIMARY KEY CLUSTERED ([ironoffercyclesid] ASC, [fanid] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE),
    CONSTRAINT [uc_ironoffercyclesidfanid] UNIQUE NONCLUSTERED ([ironoffercyclesid] ASC, [fanid] ASC) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE) ON [nFI_Indexes]
);

