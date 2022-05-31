CREATE TABLE [dbo].[NobleTransactionHistory_Narrow] (
    [FileID]        INT      NULL,
    [RowNum]        INT      NULL,
    [PaymentCardID] INT      NULL,
    [CardInputMode] CHAR (1) NULL,
    [MatchID]       INT      NULL,
    [MatchStatus]   TINYINT  NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [ixc_NobleTransactionHistoryNarrow_FileIDRowNum]
    ON [dbo].[NobleTransactionHistory_Narrow]([FileID] ASC, [RowNum] ASC) WITH (DATA_COMPRESSION = PAGE);


GO
GRANT INSERT
    ON OBJECT::[dbo].[NobleTransactionHistory_Narrow] TO [crtimport]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[NobleTransactionHistory_Narrow] TO [crtimport]
    AS [dbo];


GO
GRANT UPDATE
    ON OBJECT::[dbo].[NobleTransactionHistory_Narrow] TO [crtimport]
    AS [dbo];

