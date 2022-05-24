CREATE TABLE [MI].[SectorTotalCustomers_MyRewards_CorePrivate] (
    [ID]                          INT     IDENTITY (1, 1) NOT NULL,
    [IsPrivate]                   BIT     NOT NULL,
    [SectorID]                    TINYINT NOT NULL,
    [CustomerCountThisYear]       INT     NOT NULL,
    [OnlineCustomerCountThisYear] INT     NOT NULL,
    [CustomerCountLastYear]       INT     NOT NULL,
    [OnlineCustomerCountLastYear] INT     NOT NULL,
    CONSTRAINT [PK_MI_SectorTotalCustomers_MyRewards_CorePrivate] PRIMARY KEY CLUSTERED ([ID] ASC)
);

