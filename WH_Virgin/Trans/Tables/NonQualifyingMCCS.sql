CREATE TABLE [Trans].[NonQualifyingMCCS] (
    [mcc]              VARCHAR (4) NOT NULL,
    [createdtimestamp] DATETIME    NOT NULL,
    CONSTRAINT [pk_warehouse_nonqualifyingmccs] PRIMARY KEY CLUSTERED ([mcc] ASC)
);

