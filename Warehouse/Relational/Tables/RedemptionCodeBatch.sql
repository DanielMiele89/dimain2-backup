CREATE TABLE [Relational].[RedemptionCodeBatch] (
    [BatchID]    INT  IDENTITY (1, 1) NOT NULL,
    [BatchDate]  DATE NOT NULL,
    [CodeTypeID] INT  NOT NULL,
    PRIMARY KEY CLUSTERED ([BatchID] ASC)
);

