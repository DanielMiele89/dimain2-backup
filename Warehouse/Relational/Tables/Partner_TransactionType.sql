CREATE TABLE [Relational].[Partner_TransactionType] (
    [TransactionTypeID]          INT          IDENTITY (1, 1) NOT NULL,
    [TransactionTypeDescription] VARCHAR (50) NULL,
    CONSTRAINT [pk_transactiontype] PRIMARY KEY CLUSTERED ([TransactionTypeID] ASC)
);

