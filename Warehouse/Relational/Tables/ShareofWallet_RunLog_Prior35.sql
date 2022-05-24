CREATE TABLE [Relational].[ShareofWallet_RunLog_Prior35] (
    [ID]                   INT           IDENTITY (1, 1) NOT NULL,
    [PartnerString]        VARCHAR (100) NULL,
    [PartnerName_Formated] VARCHAR (200) NULL,
    [Mth]                  TINYINT       NULL,
    [Loyalty]              TINYINT       NULL,
    [CategorySpend]        MONEY         NULL,
    [RunTime]              DATETIME      NULL
);

