CREATE TABLE [Staging].[LionSendLoads] (
    [LionSendID]                INT NOT NULL,
    [LoadedByDI]                INT NULL,
    [LoadedByGAS]               INT NULL,
    [EmailsSent]                INT NULL,
    [Slots]                     INT NULL,
    [ActiveCustomers]           INT NULL,
    [Newsletter_able_Customers] INT NULL,
    [HyphenCustomers]           INT NULL,
    [NoPaymentCards]            INT NULL,
    PRIMARY KEY CLUSTERED ([LionSendID] ASC)
);

