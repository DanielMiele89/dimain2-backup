CREATE TABLE [Staging].[MCCExclude] (
    [MCC]          VARCHAR (4) NOT NULL,
    [ExcludeStage] TINYINT     NULL,
    PRIMARY KEY CLUSTERED ([MCC] ASC)
);

