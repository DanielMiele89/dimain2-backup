CREATE TABLE [ETL].[TableCheckpointType_OLD] (
    [CheckpointTypeID]    INT           IDENTITY (1, 1) NOT NULL,
    [TypeName]            VARCHAR (100) NOT NULL,
    [TypeDescription]     VARCHAR (200) NULL,
    [StoredProcedureName] VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_ETL_TableCheckpointType_OLD] PRIMARY KEY CLUSTERED ([CheckpointTypeID] ASC)
);

