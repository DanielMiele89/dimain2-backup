CREATE TABLE [Staging].[BrandAcquirer] (
    [BrandAcquirerID] INT      IDENTITY (1, 1) NOT NULL,
    [MOMRun]          INT      NOT NULL,
    [BrandID]         SMALLINT NOT NULL,
    [AcquirerID]      TINYINT  NOT NULL,
    [BrandMIDCount]   INT      NOT NULL,
    CONSTRAINT [PK_BrandAcquirer] PRIMARY KEY CLUSTERED ([BrandAcquirerID] ASC)
);

