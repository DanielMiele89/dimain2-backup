CREATE TABLE [Staging].[NETCharityResults] (
    [ClubName]                NVARCHAR (100)  NOT NULL,
    [LoyaltySegment]          VARCHAR (7)     NOT NULL,
    [RedeemDate]              DATE            NULL,
    [CashbackUsed]            MONEY           NULL,
    [CashbackUsedPlusGiftAid] NUMERIC (38, 6) NULL,
    [Redemptions]             INT             NULL,
    [GiftAid]                 INT             NULL,
    [CustomersLoggingIn]      INT             NULL
);

