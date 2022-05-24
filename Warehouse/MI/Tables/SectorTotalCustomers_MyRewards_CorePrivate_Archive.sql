CREATE TABLE [MI].[SectorTotalCustomers_MyRewards_CorePrivate_Archive] (
    [ID]                          INT     IDENTITY (1, 1) NOT NULL,
    [GenerationDate]              DATE    CONSTRAINT [DF_MI_SectorTotalCustomers_MyRewards_CorePrivate_Archive] DEFAULT (getdate()) NOT NULL,
    [IsPrivate]                   BIT     NOT NULL,
    [SectorID]                    TINYINT NOT NULL,
    [CustomerCountThisYear]       INT     NOT NULL,
    [OnlineCustomerCountThisYear] INT     NOT NULL,
    [CustomerCountLastYear]       INT     NOT NULL,
    [OnlineCustomerCountLastYear] INT     NOT NULL,
    CONSTRAINT [PK_MI_SectorTotalCustomers_MyRewards_CorePrivate_Archive] PRIMARY KEY CLUSTERED ([ID] ASC)
);

