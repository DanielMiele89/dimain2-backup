CREATE TABLE [Monitor].[Package_SourceType_OLD] (
    [SourceTypeID] INT          NOT NULL,
    [SourceType]   VARCHAR (20) NOT NULL,
    [MatchString]  VARCHAR (15) NULL,
    CONSTRAINT [PK__Package___7E17ECCFC36016EE_OLD] PRIMARY KEY CLUSTERED ([SourceTypeID] ASC)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Package Logging Table - holds the main types of sources from packages i.e. Task, Container, Package', @level0type = N'SCHEMA', @level0name = N'Monitor', @level1type = N'TABLE', @level1name = N'Package_SourceType_OLD';


GO
EXECUTE sp_addextendedproperty @name = N'Related_Process', @value = N'Client Data Pipeline', @level0type = N'SCHEMA', @level0name = N'Monitor', @level1type = N'TABLE', @level1name = N'Package_SourceType_OLD';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The ID that links to Package_SourceType', @level0type = N'SCHEMA', @level0name = N'Monitor', @level1type = N'TABLE', @level1name = N'Package_SourceType_OLD', @level2type = N'COLUMN', @level2name = N'SourceTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Describes the type of Source i.e. Package, Container, Task', @level0type = N'SCHEMA', @level0name = N'Monitor', @level1type = N'TABLE', @level1name = N'Package_SourceType_OLD', @level2type = N'COLUMN', @level2name = N'SourceType';

