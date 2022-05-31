CREATE TABLE [PatrickM].[accountdifference] (
    [FanID]               INT          NOT NULL,
    [sourceuid]           VARCHAR (20) NULL,
    [CINID]               INT          NULL,
    [Date]                DATE         NULL,
    [currentaccountspend] MONEY        NULL,
    [creditcardspend]     MONEY        NULL,
    [DDSpend]             MONEY        NULL,
    [DDVolume]            INT          NULL,
    [NomineeStatus]       INT          NULL,
    [CurrentAccount]      VARCHAR (14) NULL,
    [CreditCardName]      VARCHAR (24) NULL,
    [CurrentAccountType]  VARCHAR (12) NULL,
    [AccountSegmentation] VARCHAR (28) NOT NULL,
    [CreditCardSplit]     VARCHAR (24) NULL,
    [BookType]            VARCHAR (10) NOT NULL,
    [AccountType]         VARCHAR (16) NOT NULL,
    [CreditCardType]      VARCHAR (14) NOT NULL,
    [Diff_BookType]       VARCHAR (50) NULL,
    [Diff_accountype]     VARCHAR (50) NULL,
    [Diff_CreditCardType] VARCHAR (50) NULL
);

