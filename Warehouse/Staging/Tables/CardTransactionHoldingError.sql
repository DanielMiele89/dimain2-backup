CREATE TABLE [Staging].[CardTransactionHoldingError] (
    [FileID]      INT NULL,
    [RowNum]      INT NULL,
    [ErrorCode]   INT NULL,
    [ErrorColumn] INT NULL
);


GO
GRANT SELECT
    ON OBJECT::[Staging].[CardTransactionHoldingError] TO [gas]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[Staging].[CardTransactionHoldingError] TO [gas]
    AS [dbo];

