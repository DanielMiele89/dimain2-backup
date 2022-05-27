CREATE TABLE [Relational].[Customer_SchemeMembershipType] (
    [ID]             TINYINT      NOT NULL,
    [BookType]       VARCHAR (50) NOT NULL,
    [AccountType]    VARCHAR (50) NOT NULL,
    [CreditCardType] VARCHAR (50) NOT NULL,
    [FreeTrialType]  VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_Relational_SchemeMembershipType] PRIMARY KEY CLUSTERED ([ID] ASC)
);

