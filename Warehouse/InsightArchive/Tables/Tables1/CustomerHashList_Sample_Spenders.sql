﻿CREATE TABLE [InsightArchive].[CustomerHashList_Sample_Spenders] (
    [CINID]                       INT           NOT NULL,
    [CustHash]                    VARCHAR (500) NOT NULL,
    [ProxyUserID]                 INT           NOT NULL,
    [CardholderLocationIndicator] VARCHAR (50)  NOT NULL,
    PRIMARY KEY CLUSTERED ([CINID] ASC)
);

