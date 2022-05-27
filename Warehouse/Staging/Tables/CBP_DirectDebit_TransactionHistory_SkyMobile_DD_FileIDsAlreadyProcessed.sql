CREATE TABLE [Staging].[CBP_DirectDebit_TransactionHistory_SkyMobile_DD_FileIDsAlreadyProcessed] (
    [FileID]           INT      NOT NULL,
    [DateProcessed]    DATETIME NULL,
    [InsertCompleted]  BIT      NULL,
    [RowCountInserted] INT      NULL
);

