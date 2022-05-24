CREATE TABLE [MI].[Catchup] (
    [FileID]    INT NOT NULL,
    [TransRows] INT NOT NULL,
    [Processed] BIT NOT NULL,
    PRIMARY KEY CLUSTERED ([FileID] ASC)
);

