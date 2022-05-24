CREATE TABLE [Staging].[RF_Backup_Derived_Customer_MarketableByEmailStatus] (
    [ID]                    INT          IDENTITY (1, 1) NOT NULL,
    [FanID]                 INT          NOT NULL,
    [CurrentlyActive]       BIT          NOT NULL,
    [Hardbounced]           BIT          NOT NULL,
    [Unsubscribed]          BIT          NOT NULL,
    [MarketableByEmail]     BIT          NOT NULL,
    [MarketableByEmailType] VARCHAR (20) NOT NULL,
    [StartDate]             DATE         NOT NULL,
    [EndDate]               DATE         NULL
);

