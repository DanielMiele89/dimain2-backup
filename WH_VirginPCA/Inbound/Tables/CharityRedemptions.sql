CREATE TABLE [Inbound].[CharityRedemptions] (
    [DonationTransactionGUID] UNIQUEIDENTIFIER NOT NULL,
    [CharityOfferID]          INT              NOT NULL,
    [BankID]                  INT              NULL,
    [CharityName]             VARCHAR (250)    NULL,
    [CustomerGUID]            UNIQUEIDENTIFIER NULL,
    [Amount]                  DECIMAL (32, 2)  NULL,
    [RedeemedDate]            DATETIME2 (7)    NULL,
    [Currency]                VARCHAR (3)      NULL,
    [GiftAid]                 BIT              NULL,
    [ConfirmedDate]           DATETIME2 (7)    NULL,
    [CreatedAt]               DATETIME2 (7)    NULL,
    [UpdatedAt]               DATETIME2 (7)    NULL,
    [LoadDate]                DATETIME2 (7)    NOT NULL,
    [FileName]                NVARCHAR (320)   NOT NULL
);

