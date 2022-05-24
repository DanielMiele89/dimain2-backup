CREATE TABLE [MI].[GrandTotalCustomersArchive_CBP] (
    [ID]                               INT  IDENTITY (1, 1) NOT NULL,
    [GenerationDate]                   DATE NOT NULL,
    [TotalCustomerCountThisYear]       INT  NOT NULL,
    [TotalOnlineCustomerCountThisYear] INT  NOT NULL,
    [TotalCustomerCountLastYear]       INT  NOT NULL,
    [TotalOnlineCustomerCountLastYear] INT  NOT NULL,
    CONSTRAINT [PK_MI_GrandTotalCustomersArchive_CBP] PRIMARY KEY CLUSTERED ([ID] ASC)
);

