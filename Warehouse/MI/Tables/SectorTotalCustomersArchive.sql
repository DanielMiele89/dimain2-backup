CREATE TABLE [MI].[SectorTotalCustomersArchive] (
    [ID]                          INT     IDENTITY (1, 1) NOT NULL,
    [GenerationDate]              DATE    NOT NULL,
    [SectorID]                    TINYINT NOT NULL,
    [CustomerCountThisYear]       INT     NOT NULL,
    [OnlineCustomerCountThisYear] INT     NOT NULL,
    [CustomerCountLastYear]       INT     NOT NULL,
    [OnlineCustomerCountLastYear] INT     NOT NULL,
    CONSTRAINT [PK_MI_SectorTotalCustomerArchive] PRIMARY KEY CLUSTERED ([ID] ASC)
);

