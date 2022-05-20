CREATE TABLE [dbo].[MatchSelfFundedTransaction] (
    [MatchID]        INT      NOT NULL,
    [InvoiceMatchID] INT      NOT NULL,
    [IdentifiedDate] DATETIME NOT NULL,
    CONSTRAINT [PK_MatchSelfFundedTransaction_MatchID] PRIMARY KEY CLUSTERED ([MatchID] ASC)
);

