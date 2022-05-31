﻿CREATE TABLE [dbo].[CBP_DirectDebit_UpdatedTransaction_20211006_004] (
    [FileID]                    INT           NOT NULL,
    [RowNum]                    INT           NOT NULL,
    [BankID]                    VARCHAR (4)   NOT NULL,
    [SortCode]                  VARCHAR (6)   NOT NULL,
    [AccountNo]                 VARCHAR (8)   NOT NULL,
    [Amount]                    MONEY         NOT NULL,
    [OIN]                       INT           NOT NULL,
    [Date]                      DATE          NOT NULL,
    [Narrative]                 NVARCHAR (18) NOT NULL,
    [BankAccountID]             INT           NULL,
    [IssuerID]                  INT           NULL,
    [ClubID]                    INT           NULL,
    [DirectDebitOriginatorID]   INT           NULL,
    [DirectDebitCategory1ID]    INT           NULL,
    [Rate]                      FLOAT (53)    NULL,
    [TransItemID]               INT           NULL,
    [MaskedAccountNumber]       VARCHAR (8)   NULL,
    [BankAccountTypeHistoryID]  INT           NULL,
    [BankAccountType]           VARCHAR (3)   NULL,
    [IssuerBankAccountID]       INT           NULL,
    [IssuerCustomerID]          INT           NULL,
    [SourceUID]                 VARCHAR (20)  NULL,
    [FanID]                     INT           NULL,
    [FanActivationDate]         DATE          NULL,
    [DDCashbackNomineeID]       INT           NULL,
    [IsDDCashbackNominee]       BIT           NULL,
    [IssuerCustomerAttributeID] INT           NULL,
    [CustomerSegment]           VARCHAR (8)   NULL,
    [MatchStatus]               TINYINT       NULL,
    [RewardStatus]              TINYINT       NULL,
    [LoyaltyFlag]               VARCHAR (3)   NULL
);

