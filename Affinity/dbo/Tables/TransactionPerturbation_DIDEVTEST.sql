﻿CREATE TABLE [dbo].[TransactionPerturbation_DIDEVTEST] (
    [TransSequenceID]           BINARY (32)     NOT NULL,
    [ProxyUserID]               BINARY (32)     NOT NULL,
    [PerturbedDate]             DATE            NOT NULL,
    [ProxyMIDTupleID]           BINARY (32)     NOT NULL,
    [PerturbedAmount]           DECIMAL (15, 8) NOT NULL,
    [CurrencyCode]              VARCHAR (3)     NOT NULL,
    [CardholderPresentFlag]     VARCHAR (3)     NOT NULL,
    [CardType]                  VARCHAR (10)    NOT NULL,
    [CardholderPostcode]        VARCHAR (10)    NULL,
    [REW_TransSequenceID_INT]   DECIMAL (10, 8) NOT NULL,
    [REW_FanID]                 INT             NOT NULL,
    [REW_SourceUID]             VARCHAR (20)    NOT NULL,
    [REW_TranDate]              DATE            NOT NULL,
    [REW_ConsumerCombinationID] INT             NOT NULL,
    [REW_Amount]                MONEY           NULL,
    [REW_Variance]              DECIMAL (12, 5) NOT NULL,
    [REW_RandomNumber]          DECIMAL (7, 5)  NOT NULL,
    [REW_FileID]                INT             NOT NULL,
    [REW_RowNum]                INT             NOT NULL,
    [REW_Prefix]                VARCHAR (10)    NULL,
    [REW_CardholderPresentData] TINYINT         NULL,
    [REW_CardholderPostcode]    VARCHAR (5)     NULL,
    [ReportType]                VARCHAR (10)    NOT NULL,
    [ReportDate]                DATE            NOT NULL,
    [CreatedDateTime]           DATETIME        NOT NULL
);


GO
CREATE CLUSTERED INDEX [cx_Stuff]
    ON [dbo].[TransactionPerturbation_DIDEVTEST]([REW_FileID] ASC, [REW_RowNum] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);

