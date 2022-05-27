CREATE TABLE [Staging].[CBP_DirectDebit_TransactionHistory_Sky_DD_FileIDsAlreadyProcessed] (
    [FileID]           INT      NOT NULL,
    [DateProcessed]    DATETIME NULL,
    [InsertCompleted]  BIT      NULL,
    [RowCountInserted] INT      NULL
);


GO
CREATE CLUSTERED INDEX [cx_FileID]
    ON [Staging].[CBP_DirectDebit_TransactionHistory_Sky_DD_FileIDsAlreadyProcessed]([FileID] ASC);

