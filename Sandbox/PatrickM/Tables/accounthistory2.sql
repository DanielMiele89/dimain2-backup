CREATE TABLE [PatrickM].[accounthistory2] (
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
    [AccountSegmentation] VARCHAR (28) NOT NULL,
    [BookType]            VARCHAR (10) NOT NULL,
    [AccountType]         VARCHAR (16) NOT NULL,
    [CreditCardType]      VARCHAR (14) NOT NULL
);

