﻿CREATE TABLE [Staging].[MOMRun] (
    [MOMRunID] INT           IDENTITY (1, 1) NOT NULL,
    [RunDate]  SMALLDATETIME CONSTRAINT [DF_MOMRun_RunDate] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_MOMRun] PRIMARY KEY CLUSTERED ([MOMRunID] ASC)
);

