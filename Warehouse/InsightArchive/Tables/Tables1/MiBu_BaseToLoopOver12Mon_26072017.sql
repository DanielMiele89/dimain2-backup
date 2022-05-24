﻿CREATE TABLE [InsightArchive].[MiBu_BaseToLoopOver12Mon_26072017] (
    [FanID]             INT           NOT NULL,
    [cinid]             INT           NOT NULL,
    [Gender]            CHAR (1)      NULL,
    [AgeCategory]       VARCHAR (12)  NULL,
    [CameoCode]         VARCHAR (151) NOT NULL,
    [Region]            VARCHAR (30)  NULL,
    [MarketableByEmail] BIT           NULL,
    [HMcomboID]         INT           NULL,
    [HMscoreABO]        INT           NULL,
    [SpendCatABO]       VARCHAR (50)  NULL,
    [SalesABO]          INT           NULL,
    [HMscoreBRW]        INT           NULL,
    [SpendCatBRW]       VARCHAR (50)  NULL,
    [SalesBRW]          INT           NULL,
    [HMscoreHRV]        INT           NULL,
    [SpendCatHRV]       VARCHAR (50)  NULL,
    [SalesHRV]          INT           NULL,
    [HMscoreMICA]       INT           NULL,
    [SpendCatMICA]      VARCHAR (50)  NULL,
    [SalesMICA]         INT           NULL,
    [HMscoreNIC]        INT           NULL,
    [SpendCatNIC]       VARCHAR (50)  NULL,
    [SalesNIC]          INT           NULL,
    [HMscoreTOC]        INT           NULL,
    [SpendCatTOC]       VARCHAR (50)  NULL,
    [SalesTOC]          INT           NULL,
    [HMscoreVIN]        INT           NULL,
    [SpendCatVIN]       VARCHAR (50)  NULL,
    [SalesVIN]          INT           NULL,
    [TxsNIC]            INT           NULL,
    [TxsTOC]            INT           NULL,
    [TxsVIN]            INT           NULL,
    [TxsABO]            INT           NULL,
    [TxsHRV]            INT           NULL,
    [TxsMICA]           INT           NULL,
    [TxsBRW]            INT           NULL,
    [SelectionNIC]      VARCHAR (20)  NULL,
    [SelectionTOC]      VARCHAR (20)  NULL,
    [SelectionVIN]      VARCHAR (20)  NULL,
    [SelectionBRW]      VARCHAR (20)  NULL,
    [SelectionABO]      VARCHAR (20)  NULL,
    [SelectionHRV]      VARCHAR (20)  NULL,
    [SelectionMICA]     VARCHAR (20)  NULL,
    [SelectionNIC_DT]   VARCHAR (20)  NULL,
    [SelectionTOC_DT]   VARCHAR (20)  NULL,
    [SelectionVIN_DT]   VARCHAR (20)  NULL,
    [SelectionBRW_DT]   VARCHAR (20)  NULL,
    [SelectionABO_DT]   VARCHAR (20)  NULL,
    [SelectionHRV_DT]   VARCHAR (20)  NULL,
    [SelectionMICA_DT]  VARCHAR (20)  NULL,
    [NIC_DT]            FLOAT (53)    NULL,
    [TOC_DT]            FLOAT (53)    NULL,
    [VIN_DT]            FLOAT (53)    NULL,
    [BRW_DT]            FLOAT (53)    NULL,
    [ABO_DT]            FLOAT (53)    NULL,
    [HRV_DT]            FLOAT (53)    NULL,
    [MICA_DT]           FLOAT (53)    NULL,
    [postalsector]      VARCHAR (20)  NULL
);


GO
CREATE CLUSTERED INDEX [C_INX]
    ON [InsightArchive].[MiBu_BaseToLoopOver12Mon_26072017]([cinid] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);

