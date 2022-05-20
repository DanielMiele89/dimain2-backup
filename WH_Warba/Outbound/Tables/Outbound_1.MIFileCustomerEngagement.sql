CREATE TABLE [Outbound].[Outbound.MIFileCustomerEngagement] (
    [ID]                           INT             NOT NULL,
    [Date]                         DATE            NOT NULL,
    [ActiveCustomerBase]           BIGINT          NOT NULL,
    [CustomerActivations]          DATE            NOT NULL,
    [CustomerDeactivations]        INT             NOT NULL,
    [CashbackEarned]               DECIMAL (32, 2) NOT NULL,
    [IncentivisedTrans]            BIGINT          NOT NULL,
    [Transactions]                 BIGINT          NOT NULL,
    [UniqueCustomersEarnings]      INT             NOT NULL,
    [UniqueCustomerEarningsByDate] INT             NOT NULL
);

