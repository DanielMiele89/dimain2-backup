CREATE TABLE [Processing].[Package_SourceType] (
    [SourceTypeID] INT          IDENTITY (1, 1) NOT NULL,
    [SourceType]   VARCHAR (20) NOT NULL,
    [MatchString]  VARCHAR (15) NULL,
    PRIMARY KEY CLUSTERED ([SourceTypeID] ASC)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Package Logging Table - holds the main types of sources from packages i.e. Task, Container, Package', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Package_SourceType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The ID that links to Package_SourceType', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Package_SourceType', @level2type = N'COLUMN', @level2name = N'SourceTypeID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Describes the type of Source i.e. Package, Container, Task', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Package_SourceType', @level2type = N'COLUMN', @level2name = N'SourceType';

