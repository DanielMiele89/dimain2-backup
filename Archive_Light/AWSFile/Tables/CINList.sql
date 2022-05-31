﻿CREATE TABLE [AWSFile].[CINList] (
    [CINID] INT          NOT NULL,
    [CIN]   VARCHAR (20) NULL,
    CONSTRAINT [PK_AWSFile_CINList] PRIMARY KEY CLUSTERED ([CINID] ASC)
);
