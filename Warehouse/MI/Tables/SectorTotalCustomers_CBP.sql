CREATE TABLE [MI].[SectorTotalCustomers_CBP] (
    [SectorID]                    TINYINT NOT NULL,
    [CustomerCountThisYear]       INT     NOT NULL,
    [OnlineCustomerCountThisYear] INT     NOT NULL,
    [CustomerCountLastYear]       INT     NOT NULL,
    [OnlineCustomerCountLastYear] INT     NOT NULL,
    CONSTRAINT [PK_MI_SectorTotalCustomers_CBP] PRIMARY KEY CLUSTERED ([SectorID] ASC)
);

