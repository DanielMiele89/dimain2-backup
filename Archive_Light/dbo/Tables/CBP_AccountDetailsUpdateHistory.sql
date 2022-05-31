﻿CREATE TABLE [dbo].[CBP_AccountDetailsUpdateHistory] (
    [FileID]                                INT          NULL,
    [RowNum]                                INT          NULL,
    [CustomerID]                            VARCHAR (10) NULL,
    [BankID]                                VARCHAR (4)  NULL,
    [SortCode]                              VARCHAR (6)  NULL,
    [AccountType]                           VARCHAR (3)  NULL,
    [AccountStatus]                         SMALLINT     NULL,
    [PortfolioCode]                         VARCHAR (5)  NULL,
    [LoyaltyType]                           VARCHAR (3)  NULL,
    [DDCashBackNominee]                     VARCHAR (10) NULL,
    [AccountRelationship]                   VARCHAR (2)  NULL,
    [Eligible]                              VARCHAR (1)  NULL,
    [CustomerDeleted]                       SMALLINT     NULL,
    [BankAccountID]                         INT          NULL,
    [IssuerCustomerID]                      INT          NULL,
    [IssuerBankAccountID]                   INT          NULL,
    [DDCashBackNominee_IssuerCustomerID]    INT          NULL,
    [DDCashBackNominee_IssuerBankAccountID] INT          NULL,
    [NewAccount]                            BIT          NULL,
    [NewCustomerToAccount]                  BIT          NULL,
    [IsValid]                               BIT          NULL,
    [FanID]                                 INT          NULL
);
