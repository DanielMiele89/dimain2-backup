CREATE TABLE [dbo].[TransactionType] (
    [ID]          TINYINT        NOT NULL,
    [Name]        NVARCHAR (25)  NOT NULL,
    [Description] NVARCHAR (500) NOT NULL,
    [Multiplier]  SMALLINT       NOT NULL,
    CONSTRAINT [PK_TransactionType] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
GRANT SELECT
    ON OBJECT::[dbo].[TransactionType] TO [virgin_etl_user]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[TransactionType] TO [visa_etl_user]
    AS [dbo];

