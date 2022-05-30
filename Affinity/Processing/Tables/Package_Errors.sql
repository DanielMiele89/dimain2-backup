CREATE TABLE [Processing].[Package_Errors] (
    [ID]               INT              IDENTITY (1, 1) NOT NULL,
    [RunID]            INT              NOT NULL,
    [PackageID]        UNIQUEIDENTIFIER NOT NULL,
    [SourceID]         UNIQUEIDENTIFIER NOT NULL,
    [RunStartDateTime] DATETIME         NULL,
    [ErrorCode]        INT              NOT NULL,
    [ErrorDetails]     NVARCHAR (MAX)   NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Package Error Logging table - holds the errors that have occurred on a package for a run', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Package_Errors';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'IDENTITY column', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Package_Errors', @level2type = N'COLUMN', @level2name = N'ID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'An ID that groups all sources that occur in a single run together', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Package_Errors', @level2type = N'COLUMN', @level2name = N'RunID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The SSIS PackageID -- it is a SSIS System Variable', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Package_Errors', @level2type = N'COLUMN', @level2name = N'PackageID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The SSIS SourceID -- it is a SSIS System Variable and represents any object in the control flow', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Package_Errors', @level2type = N'COLUMN', @level2name = N'SourceID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The DateTime that the error was inserted into the table', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Package_Errors', @level2type = N'COLUMN', @level2name = N'RunStartDateTime';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The error code as returned by SSIS', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Package_Errors', @level2type = N'COLUMN', @level2name = N'ErrorCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The error details of the package as returned by SSIS', @level0type = N'SCHEMA', @level0name = N'Processing', @level1type = N'TABLE', @level1name = N'Package_Errors', @level2type = N'COLUMN', @level2name = N'ErrorDetails';

