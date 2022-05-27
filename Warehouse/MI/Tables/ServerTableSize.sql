CREATE TABLE [MI].[ServerTableSize] (
    [ID]           INT           IDENTITY (1, 1) NOT NULL,
    [SizeDate]     DATE          CONSTRAINT [DF_MI_ServerTableSize_SizeDate] DEFAULT (getdate()) NULL,
    [ServerName]   VARCHAR (50)  NOT NULL,
    [SchemaName]   VARCHAR (50)  NOT NULL,
    [DatabaseName] VARCHAR (50)  NOT NULL,
    [TableName]    VARCHAR (100) NOT NULL,
    [TableRows]    BIGINT        NULL,
    [KBReserved]   BIGINT        NULL,
    [KBData]       BIGINT        NULL,
    [KBIndexSize]  BIGINT        NULL,
    [KBUnused]     BIGINT        NULL,
    CONSTRAINT [PK_MI_ServerTableSize] PRIMARY KEY CLUSTERED ([ID] ASC)
);

