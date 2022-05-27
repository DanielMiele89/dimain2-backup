CREATE TABLE [Relational].[CreditCardPostCode] (
    [LocationID]      INT         IDENTITY (1, 1) NOT NULL,
    [LocationCountry] VARCHAR (3) NOT NULL,
    [PostCode]        VARCHAR (9) NOT NULL,
    CONSTRAINT [PK_Relational_CreditCardPostCode] PRIMARY KEY CLUSTERED ([LocationID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Stuff]
    ON [Relational].[CreditCardPostCode]([LocationCountry] ASC, [PostCode] ASC)
    INCLUDE([LocationID]);

