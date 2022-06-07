CREATE TABLE [dbo].[SLC_TransactionType] (
    [SLC_TransactionTypeID] SMALLINT       NOT NULL,
    [TypeName]              VARCHAR (25)   NOT NULL,
    [TypeDescription]       VARCHAR (500)  NOT NULL,
    [Multiplier]            SMALLINT       NOT NULL,
    [CreatedDateTime]       DATETIME2 (7)  NOT NULL,
    [UpdatedDateTime]       DATETIME2 (7)  NOT NULL,
    [MD5]                   VARBINARY (16) NOT NULL,
    CONSTRAINT [PK_TransactionType] PRIMARY KEY CLUSTERED ([SLC_TransactionTypeID] ASC) WITH (FILLFACTOR = 90)
);

