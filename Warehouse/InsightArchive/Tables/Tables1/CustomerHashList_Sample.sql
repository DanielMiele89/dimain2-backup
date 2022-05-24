CREATE TABLE [InsightArchive].[CustomerHashList_Sample] (
    [CINID]                       INT              NOT NULL,
    [CustHash]                    VARCHAR (500)    NOT NULL,
    [ProxyUserID]                 INT              NOT NULL,
    [CardholderLocationIndicator] VARCHAR (50)     NOT NULL,
    [HashBin]                     VARBINARY (8000) NULL,
    PRIMARY KEY CLUSTERED ([CINID] ASC)
);

