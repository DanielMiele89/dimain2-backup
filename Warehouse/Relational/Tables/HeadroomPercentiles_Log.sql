CREATE TABLE [Relational].[HeadroomPercentiles_Log] (
    [PartnerString]        VARCHAR (50)    NULL,
    [PartnerName_Formated] VARCHAR (8000)  NULL,
    [PartnerPct1]          NUMERIC (21, 6) NULL,
    [PartnerPct2]          NUMERIC (21, 6) NULL,
    [PartnerPct3]          NUMERIC (21, 6) NULL,
    [CategoryWalletSize1]  NUMERIC (21, 6) NULL,
    [CategoryWalletSize2]  NUMERIC (21, 6) NULL,
    [CategoryWalletSize3]  NUMERIC (21, 6) NULL,
    [RunDate]              DATETIME        NOT NULL,
    [Mth]                  VARCHAR (3)     NULL,
    [ID]                   INT             IDENTITY (1, 1) NOT NULL
);

