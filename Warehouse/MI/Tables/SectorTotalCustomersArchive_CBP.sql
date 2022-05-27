CREATE TABLE [MI].[SectorTotalCustomersArchive_CBP] (
    [ID]                          INT     IDENTITY (1, 1) NOT NULL,
    [GenerationDate]              DATE    NOT NULL,
    [SectorID]                    TINYINT NOT NULL,
    [CustomerCountThisYear]       INT     NOT NULL,
    [OnlineCustomerCountThisYear] INT     NOT NULL,
    [CustomerCountLastYear]       INT     NOT NULL,
    [OnlineCustomerCountLastYear] INT     NOT NULL,
    CONSTRAINT [PK_MI_SectorTotalCustomerArchive_CBP] PRIMARY KEY CLUSTERED ([ID] ASC)
);

