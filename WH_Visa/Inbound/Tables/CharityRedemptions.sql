CREATE TABLE [Inbound].[CharityRedemptions] (
    [DonationTransactionGUID] UNIQUEIDENTIFIER NOT NULL,
    [CharityOfferID]          INT              NOT NULL,
    [BankID]                  VARCHAR (250)    NULL,
    [CharityName]             VARCHAR (250)    NULL,
    [CustomerGUID]            UNIQUEIDENTIFIER NULL,
    [Amount]                  DECIMAL (8, 4)   NULL,
    [RedeemedDate]            DATETIME2 (7)    NULL,
    [Currency]                VARCHAR (3)      NULL,
    [GiftAid]                 BIT              NULL,
    [ConfirmedDate]           DATETIME2 (7)    NULL,
    [CreatedAt]               DATETIME2 (7)    NULL,
    [UpdatedAt]               DATETIME2 (7)    NULL,
    [LoadDate]                DATETIME2 (7)    NULL,
    [FileName]                NVARCHAR (100)   NULL
);

