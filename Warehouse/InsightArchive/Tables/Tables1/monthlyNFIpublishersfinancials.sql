CREATE TABLE [InsightArchive].[monthlyNFIpublishersfinancials] (
    [calendarmonth]      VARCHAR (6)    NULL,
    [club]               NVARCHAR (100) NOT NULL,
    [TotalSpend]         MONEY          NULL,
    [GrossCommission]    MONEY          NULL,
    [cashbackamount]     MONEY          NULL,
    [Transactions]       INT            NULL,
    [commission_exclVat] MONEY          NULL,
    [reward_amount]      FLOAT (53)     NULL,
    [publisher_amount]   FLOAT (53)     NULL,
    [total_overide]      MONEY          NULL,
    [Spenders]           INT            NULL,
    [retailers]          INT            NULL
);

