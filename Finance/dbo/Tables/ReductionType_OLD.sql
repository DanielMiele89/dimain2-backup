CREATE TABLE [dbo].[ReductionType_OLD] (
    [ReductionTypeID]         TINYINT      NOT NULL,
    [ReductionTypeName]       VARCHAR (30) NOT NULL,
    [ReductionTypeColumnName] VARCHAR (30) NOT NULL,
    CONSTRAINT [PK_ReductionType_OLD] PRIMARY KEY CLUSTERED ([ReductionTypeID] ASC)
);

