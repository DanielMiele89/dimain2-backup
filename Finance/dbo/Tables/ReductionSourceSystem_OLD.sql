CREATE TABLE [dbo].[ReductionSourceSystem_OLD] (
    [ReductionSourceSystemID] TINYINT       NOT NULL,
    [SourceSystemName]        VARCHAR (100) NOT NULL,
    [SourceSystemDescription] VARCHAR (200) NULL,
    [SourceSystemColumn]      VARCHAR (50)  NOT NULL,
    CONSTRAINT [PK_ReductionSourceSystem_OLD] PRIMARY KEY CLUSTERED ([ReductionSourceSystemID] ASC)
);

