﻿CREATE TABLE [Staging].[VocaFile_AccountRecord_AllEntries] (
    [RecordType]         VARCHAR (MAX) NULL,
    [AmendmentDate]      DATE          NULL,
    [ServiceUserNumber]  INT           NULL,
    [AccountSortingCode] VARCHAR (MAX) NULL,
    [AccountType]        VARCHAR (MAX) NULL,
    [AccountName]        VARCHAR (MAX) NULL,
    [PadderRecord]       VARCHAR (MAX) NULL,
    [StartDate]          VARCHAR (10)  NOT NULL
);

