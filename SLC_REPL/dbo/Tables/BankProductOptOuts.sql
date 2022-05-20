CREATE TABLE [dbo].[BankProductOptOuts] (
    [FanID]         INT      NOT NULL,
    [BankProductID] TINYINT  NOT NULL,
    [OptOutDate]    DATETIME NOT NULL,
    [OptBackInDate] DATETIME NULL,
    CONSTRAINT [PK_BankProductOptOuts] PRIMARY KEY CLUSTERED ([FanID] ASC, [BankProductID] ASC, [OptOutDate] ASC)
);

