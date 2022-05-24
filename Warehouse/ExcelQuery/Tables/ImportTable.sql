CREATE TABLE [ExcelQuery].[ImportTable] (
    [ID]         INT          IDENTITY (1, 1) NOT NULL,
    [ImportDesc] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_ExcelQuery_ImportTable] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
GRANT SELECT
    ON OBJECT::[ExcelQuery].[ImportTable] TO [ExcelQueryOp]
    AS [dbo];

