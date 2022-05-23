CREATE TABLE [dbo].[EarningType_OLD] (
    [EarningTypeID]         TINYINT      NOT NULL,
    [EarningTypeName]       VARCHAR (30) NOT NULL,
    [EarningTypeColumnName] VARCHAR (30) NOT NULL,
    CONSTRAINT [PK_EarningType_OLD] PRIMARY KEY CLUSTERED ([EarningTypeID] ASC)
);

