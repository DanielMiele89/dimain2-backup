﻿CREATE TABLE [Staging].[CreditCardLoad_InitialStage] (
    [FileID]                 INT          NOT NULL,
    [RowNum]                 INT          NOT NULL,
    [OriginatorReference]    VARCHAR (6)  NOT NULL,
    [LocationCountry]        VARCHAR (3)  NOT NULL,
    [MID]                    VARCHAR (50) NOT NULL,
    [Narrative]              VARCHAR (50) NOT NULL,
    [MCC]                    VARCHAR (4)  NOT NULL,
    [PostCode]               VARCHAR (9)  NOT NULL,
    [CIN]                    VARCHAR (15) NOT NULL,
    [CardholderPresentMC]    CHAR (1)     NOT NULL,
    [Amount]                 SMALLMONEY   NOT NULL,
    [TranDateString]         VARCHAR (10) NOT NULL,
    [TranDate]               DATE         NULL,
    [ConsumerCombinationID]  INT          NULL,
    [SecondaryCombinationID] INT          NULL,
    [RequiresSecondaryID]    BIT          CONSTRAINT [DF_Staging_CreditCardLoad_InitialStage_RequiresSecondaryID] DEFAULT ((0)) NOT NULL,
    [MCCID]                  SMALLINT     NULL,
    [LocationID]             INT          NULL,
    [CINID]                  INT          NULL,
    [PaymentTypeID]          TINYINT      CONSTRAINT [DF_Staging_CreditCardLoad_InitialStage_PaymentTypeID] DEFAULT ((1)) NOT NULL,
    [FanID]                  INT          NULL,
    CONSTRAINT [PK_Staging_CreditCardLoad_InitialStage] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC)
);
