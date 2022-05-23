CREATE TABLE [dbo].[PaymentCard] (
    [ID]               INT          IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [MaskedCardNumber] VARCHAR (19) NOT NULL,
    [Date]             DATETIME     NOT NULL,
    [CardTypeID]       TINYINT      NOT NULL,
    CONSTRAINT [PK_PaymentCard] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
GRANT SELECT
    ON OBJECT::[dbo].[PaymentCard] TO [Analyst]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[PaymentCard] TO [PII_Removed]
    AS [dbo];

