CREATE TABLE [dbo].[Fan_POC2Reset_20130812] (
    [FanID]                 INT           NOT NULL,
    [Current_AgreedTCsDate] DATETIME      NULL,
    [CustomerStatus]        INT           NOT NULL,
    [MatchID]               INT           NOT NULL,
    [TransactionDate]       DATETIME      NOT NULL,
    [Amount]                SMALLMONEY    NOT NULL,
    [MatchStatus]           INT           NOT NULL,
    [MatchStatusName]       NVARCHAR (50) NOT NULL,
    [MatchRewardStatus]     INT           NOT NULL,
    [clubcash]              SMALLMONEY    NULL,
    [invoiceid]             INT           NULL
);

