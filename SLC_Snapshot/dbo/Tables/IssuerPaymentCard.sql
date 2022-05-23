CREATE TABLE [dbo].[IssuerPaymentCard] (
    [ID]               INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [IssuerCustomerID] INT      NOT NULL,
    [BankAccountID]    INT      NULL,
    [PaymentCardID]    INT      NOT NULL,
    [Date]             DATETIME NOT NULL,
    [Status]           TINYINT  NOT NULL,
    [StatusChangeDate] DATETIME NULL,
    CONSTRAINT [PK_IssuerPaymentCard] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 95)
);


GO
CREATE NONCLUSTERED INDEX [sn_Stuff01]
    ON [dbo].[IssuerPaymentCard]([PaymentCardID] ASC)
    INCLUDE([IssuerCustomerID]) WITH (FILLFACTOR = 70)
    ON [SLC_REPL_Indexes];


GO
GRANT SELECT
    ON OBJECT::[dbo].[IssuerPaymentCard] TO [Analyst]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[IssuerPaymentCard] TO [PII_Removed]
    AS [dbo];

