CREATE TABLE [Staging].[OPETables] (
    [OPETableID] INT            IDENTITY (1, 1) NOT NULL,
    [TableName]  NVARCHAR (250) NULL,
    [Table]      NVARCHAR (100) NULL,
    PRIMARY KEY CLUSTERED ([OPETableID] ASC)
);

