CREATE TABLE [Relational].[ShareofWallet_RunLog] (
    [ID]                   INT           IDENTITY (1, 1) NOT NULL,
    [PartnerString]        VARCHAR (100) NULL,
    [PartnerName_Formated] VARCHAR (200) NULL,
    [Mth]                  TINYINT       NULL,
    [Loyalty]              TINYINT       NULL,
    [CategorySpend]        MONEY         NULL,
    [RunTime]              DATETIME      NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

