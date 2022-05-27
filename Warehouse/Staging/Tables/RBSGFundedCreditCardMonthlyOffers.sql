CREATE TABLE [Staging].[RBSGFundedCreditCardMonthlyOffers] (
    [TranID]                        INT NOT NULL,
    [FileID]                        INT NULL,
    [RowNum]                        INT NULL,
    [AdditionalCashbackAwardTypeID] INT NULL,
    PRIMARY KEY CLUSTERED ([TranID] ASC)
);

