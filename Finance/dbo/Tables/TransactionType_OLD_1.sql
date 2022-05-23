CREATE TABLE [dbo].[TransactionType_OLD] (
    [TransactionTypeID] SMALLINT      NOT NULL,
    [TypeName]          VARCHAR (25)  NOT NULL,
    [TypeDescription]   VARCHAR (500) NOT NULL,
    [Multiplier]        SMALLINT      NOT NULL,
    [CreatedDateTime]   DATETIME2 (7) NOT NULL,
    [UpdatedDateTime]   DATETIME2 (7) NOT NULL,
    CONSTRAINT [PK_TransactionType_OLD] PRIMARY KEY CLUSTERED ([TransactionTypeID] ASC)
);

