CREATE TABLE [dbo].[TableUsageData] (
    [ID]         INT           IDENTITY (1, 1) NOT NULL,
    [DB]         VARCHAR (50)  NOT NULL,
    [object_id]  BIGINT        NOT NULL,
    [index_id]   BIGINT        NOT NULL,
    [LastUpdate] DATETIME      NULL,
    [Table Name] VARCHAR (100) NOT NULL,
    [Table Rows] BIGINT        NOT NULL,
    [Index Name] VARCHAR (100) NULL,
    [IndexType]  VARCHAR (50)  NOT NULL,
    [Writes]     INT           NOT NULL,
    [Reads]      INT           NOT NULL
);

