CREATE TABLE [MI].[TotalBrandSpend_RBSG_Brand_Feb2020] (
    [ID]                 INT          IDENTITY (1, 1) NOT NULL,
    [FilterID]           INT          NULL,
    [BrandID]            INT          NULL,
    [BrandName]          VARCHAR (50) NULL,
    [SectorID]           INT          NULL,
    [SectorName]         VARCHAR (50) NULL,
    [TransactionChannel] VARCHAR (20) NULL,
    [CustomerType]       VARCHAR (20) NULL,
    [TransactionType]    VARCHAR (20) NULL,
    [Amount]             MONEY        NULL,
    [Transactions]       BIGINT       NULL,
    [Customers]          INT          NULL,
    [TotalCustomers]     INT          NULL,
    [CurrentYear]        BIT          NULL
);

