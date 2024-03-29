﻿CREATE TABLE [Relational].[CINList] (
    [CINID] INT          IDENTITY (1, 1) NOT NULL,
    [CIN]   VARCHAR (20) NULL,
    CONSTRAINT [PK_CINList] PRIMARY KEY CLUSTERED ([CINID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_CINList_CIN]
    ON [Relational].[CINList]([CIN] ASC) WITH (FILLFACTOR = 80);

