CREATE TABLE [MI].[GrandTotalCustomers_MyRewards_CorePrivate_Archive] (
    [ID]                               INT  IDENTITY (1, 1) NOT NULL,
    [GenerationDate]                   DATE CONSTRAINT [PK_MI_GrandTotalCustomers_MyRewards_CorePrivate_Archive_GenerationDate] DEFAULT (getdate()) NOT NULL,
    [IsPrivate]                        BIT  NOT NULL,
    [TotalCustomerCountThisYear]       INT  NOT NULL,
    [TotalOnlineCustomerCountThisYear] INT  NOT NULL,
    [TotalCustomerCountLastYear]       INT  NOT NULL,
    [TotalOnlineCustomerCountLastYear] INT  NOT NULL,
    CONSTRAINT [PK_MI_GrandTotalCustomers_MyRewards_CorePrivate_Archive] PRIMARY KEY CLUSTERED ([ID] ASC)
);

