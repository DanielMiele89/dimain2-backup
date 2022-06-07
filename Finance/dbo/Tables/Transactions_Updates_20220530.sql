CREATE TABLE [dbo].[Transactions_Updates_20220530] (
    [TransactionID]           INT          NOT NULL,
    [SourceID]                VARCHAR (36) NOT NULL,
    [SourceTypeID]            SMALLINT     NOT NULL,
    [OriginalOfferID]         INT          NOT NULL,
    [UpdatedOfferID]          INT          NOT NULL,
    [OriginalEarningSourceID] SMALLINT     NOT NULL,
    [UpdatedEarningSourceID]  SMALLINT     NOT NULL
);

