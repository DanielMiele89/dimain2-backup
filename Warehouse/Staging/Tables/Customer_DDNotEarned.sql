CREATE TABLE [Staging].[Customer_DDNotEarned] (
    [ID]            INT          IDENTITY (1, 1) NOT NULL,
    [FanID]         INT          NOT NULL,
    [BankAccountID] INT          NOT NULL,
    [AccountName]   VARCHAR (40) NOT NULL,
    [AccountNo]     VARCHAR (3)  NOT NULL,
    [ChangeDate]    DATE         NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

