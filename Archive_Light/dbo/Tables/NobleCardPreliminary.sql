CREATE TABLE [dbo].[NobleCardPreliminary] (
    [RowNum]        INT          NULL,
    [CardStatus]    CHAR (3)     NULL,
    [CardStopCode]  VARCHAR (4)  NULL,
    [CIN]           VARCHAR (10) NULL,
    [BankID]        VARCHAR (4)  NULL,
    [FileID]        INT          NULL,
    [PaymentCardID] INT          NULL,
    [BankAccountID] INT          NULL,
    [CustomerID]    INT          NULL
);


GO
CREATE CLUSTERED INDEX [ixc_NobleCardPreliminary]
    ON [dbo].[NobleCardPreliminary]([FileID] ASC, [RowNum] ASC);

