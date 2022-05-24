CREATE TABLE [Staging].[__RBSGFundedCreditCardMonthlyOffers_Archived] (
    [TranID]                        INT NOT NULL,
    [FileID]                        INT NULL,
    [RowNum]                        INT NULL,
    [AdditionalCashbackAwardTypeID] INT NULL,
    PRIMARY KEY CLUSTERED ([TranID] ASC)
);

