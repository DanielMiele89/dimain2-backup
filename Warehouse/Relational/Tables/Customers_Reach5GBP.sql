CREATE TABLE [Relational].[Customers_Reach5GBP] (
    [FanID]    INT  NOT NULL,
    [Reached]  DATE NOT NULL,
    [Redeemed] BIT  NOT NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC) WITH (FILLFACTOR = 90)
);

