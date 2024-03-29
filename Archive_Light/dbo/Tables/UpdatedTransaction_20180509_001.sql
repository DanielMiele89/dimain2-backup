﻿CREATE TABLE [dbo].[UpdatedTransaction_20180509_001] (
    [RowNum]                INT           NULL,
    [BankID]                VARCHAR (4)   NULL,
    [PrivatePan]            VARCHAR (19)  NULL,
    [ClearStatus]           VARCHAR (3)   NULL,
    [MTI]                   VARCHAR (4)   NULL,
    [FunctionCode]          VARCHAR (4)   NULL,
    [ReversalInd]           CHAR (1)      NULL,
    [ProcessCode]           VARCHAR (9)   NULL,
    [OriginatorID]          VARCHAR (11)  NULL,
    [MerchantID]            NVARCHAR (50) NULL,
    [TerminalID]            VARCHAR (8)   NULL,
    [LocationName]          NVARCHAR (22) NULL,
    [LocationAddress]       NVARCHAR (18) NULL,
    [LocationCountry]       NVARCHAR (3)  NULL,
    [MCC]                   VARCHAR (4)   NULL,
    [CardholderPresentData] CHAR (1)      NULL,
    [TranDate]              VARCHAR (10)  NULL,
    [TranCurrencyCode]      VARCHAR (4)   NULL,
    [TranCurrencyAmt]       VARCHAR (13)  NULL,
    [RecnCurrencyCode]      VARCHAR (4)   NULL,
    [RecnCurrencyAmt]       VARCHAR (13)  NULL,
    [PWCBAmt]               VARCHAR (13)  NULL,
    [PostFPInd]             CHAR (1)      NULL,
    [PostStatus]            CHAR (1)      NULL,
    [FileID]                INT           NULL,
    [PaymentCardID]         INT           NULL,
    [PanID]                 INT           NULL,
    [RetailOutletID]        INT           NULL,
    [IronOfferMemberID]     INT           NULL,
    [MatchID]               INT           NULL,
    [BillingRuleID]         INT           NULL,
    [MarketingRuleID]       INT           NULL,
    [CompositeID]           BIGINT        NULL,
    [MatchStatus]           TINYINT       NULL,
    [FanID]                 INT           NULL,
    [RewardStatus]          TINYINT       NULL,
    [Amount]                MONEY         NULL,
    [CardInputMode]         CHAR (1)      NULL
);

