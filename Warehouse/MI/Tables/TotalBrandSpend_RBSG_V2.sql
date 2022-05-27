﻿CREATE TABLE [MI].[TotalBrandSpend_RBSG_V2] (
    [ID]                              INT          NOT NULL,
    [FilterID]                        INT          NULL,
    [IsRewardPartner]                 BIT          NULL,
    [BrandID]                         INT          NULL,
    [BrandName]                       VARCHAR (50) NULL,
    [SectorID]                        INT          NULL,
    [SectorName]                      VARCHAR (50) NULL,
    [SectorGroupID]                   INT          NULL,
    [SectorGroupName]                 VARCHAR (50) NULL,
    [TransactionChannel]              VARCHAR (20) NULL,
    [CustomerType]                    VARCHAR (20) NULL,
    [TransactionType]                 VARCHAR (20) NULL,
    [Amount]                          MONEY        NULL,
    [AmountOnline]                    MONEY        NULL,
    [Transactions]                    BIGINT       NULL,
    [Customers]                       INT          NULL,
    [CustomersPerSector]              INT          NULL,
    [CustomersPerSectorGroup]         INT          NULL,
    [TotalCustomers]                  INT          NULL,
    [AmountLastYear]                  MONEY        NULL,
    [AmountOnlineLastYear]            MONEY        NULL,
    [TransactionsLastYear]            BIGINT       NULL,
    [CustomersLastYear]               INT          NULL,
    [CustomersPerSectorLastYear]      INT          NULL,
    [CustomersPerSectorGroupLastYear] INT          NULL,
    [LastAudited]                     DATE         NULL,
    [AmountExclRefunds]               FLOAT (53)   NULL,
    [AmountExclRefundsOnline]         FLOAT (53)   NULL,
    [AmountExclRefundsLastYear]       FLOAT (53)   NULL,
    [AmountExclRefundsOnlineLastYear] FLOAT (53)   NULL
);

