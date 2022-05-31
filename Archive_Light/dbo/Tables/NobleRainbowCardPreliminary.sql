CREATE TABLE [dbo].[NobleRainbowCardPreliminary] (
    [FileID]         INT          NOT NULL,
    [RowNum]         INT          NOT NULL,
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
    [IsValid]        BIT          NULL,
    CONSTRAINT [PK_NobleRainbowCardPreliminary] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC)
);

