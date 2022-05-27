CREATE TABLE [Relational].[Customer_PartnerEarn] (
    [FanID]        INT      NOT NULL,
    [PartnerID]    SMALLINT NOT NULL,
    [First_Tran]   DATE     NULL,
    [Last_Tran]    DATE     NULL,
    [Spend]        MONEY    NULL,
    [Transactions] INT      NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC, [PartnerID] ASC)
);

