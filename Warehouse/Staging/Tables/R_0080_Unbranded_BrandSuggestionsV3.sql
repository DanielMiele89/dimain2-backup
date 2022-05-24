﻿CREATE TABLE [Staging].[R_0080_Unbranded_BrandSuggestionsV3] (
    [Suggested_BrandID]          SMALLINT        NOT NULL,
    [Suggested_BrandName]        VARCHAR (50)    NOT NULL,
    [CC_BrandID]                 SMALLINT        NOT NULL,
    [ConsumerCombinationID]      INT             NOT NULL,
    [Narrative]                  VARCHAR (50)    NOT NULL,
    [MCCDescription]             VARCHAR (200)   NOT NULL,
    [LastTransaction]            DATE            NULL,
    [TransactionAmount_LastYear] MONEY           NULL,
    [Transactions_LastYear]      INT             NULL,
    [ATV_LastYear]               MONEY           NULL,
    [ATF_LastYear]               NUMERIC (38, 6) NULL,
    [SectorName]                 VARCHAR (50)    NULL
);

