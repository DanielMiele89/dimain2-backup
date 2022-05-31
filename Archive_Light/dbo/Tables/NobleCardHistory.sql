CREATE TABLE [dbo].[NobleCardHistory] (
    [FileID]         INT          NULL,
    [RowNum]         INT          NULL,
    [CardStatus]     CHAR (3)     NULL,
    [CardStopCode]   VARCHAR (4)  NULL,
    [CIN]            VARCHAR (10) NULL,
    [BankID]         VARCHAR (4)  NULL,
    [PaymentCardID]  INT          NULL,
    [BankAccountID]  INT          NULL,
    [CustomerID]     INT          NULL,
    [PanID]          INT          NULL,
    [NewCard]        BIT          NULL,
    [NewCustomer]    BIT          NULL,
    [NewBankAccount] BIT          NULL,
    [IsValid]        BIT          NULL
);


GO
CREATE CLUSTERED INDEX [ixc_NobleCardHistory]
    ON [dbo].[NobleCardHistory]([FileID] ASC, [RowNum] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);


GO
GRANT INSERT
    ON OBJECT::[dbo].[NobleCardHistory] TO [crtimport]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[NobleCardHistory] TO [crtimport]
    AS [dbo];

