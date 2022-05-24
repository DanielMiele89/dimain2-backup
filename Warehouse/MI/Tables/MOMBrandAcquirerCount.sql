CREATE TABLE [MI].[MOMBrandAcquirerCount] (
    [BrandAcquirerID]  INT      IDENTITY (1, 1) NOT NULL,
    [RunDate]          DATETIME CONSTRAINT [DF_MI_MOMBrandAcquirerCount_Rundate] DEFAULT (getdate()) NOT NULL,
    [BrandID]          SMALLINT NOT NULL,
    [AcquirerID]       TINYINT  NOT NULL,
    [CombinationCount] INT      NOT NULL,
    CONSTRAINT [PK_BrandAcquirer] PRIMARY KEY CLUSTERED ([BrandAcquirerID] ASC)
);

