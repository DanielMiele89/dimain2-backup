CREATE TABLE [Derived].[Customer_Reach5GBPDate] (
    [ID]                        INT             IDENTITY (1, 1) NOT NULL,
    [FanID]                     BIGINT          NOT NULL,
    [CashbackAvailable]         DECIMAL (19, 2) NOT NULL,
    [PreviousCashbackAvailable] DECIMAL (19, 2) NOT NULL,
    [Reach5GBPDate]             DATE            NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC) WITH (FILLFACTOR = 80)
);

