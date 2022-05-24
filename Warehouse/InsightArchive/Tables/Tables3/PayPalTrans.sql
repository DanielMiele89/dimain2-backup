CREATE TABLE [InsightArchive].[PayPalTrans] (
    [FileID]                INT  NOT NULL,
    [RowNum]                INT  NOT NULL,
    [TranDate]              DATE NOT NULL,
    [ConsumerCombinationID] INT  NOT NULL,
    PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC)
);

