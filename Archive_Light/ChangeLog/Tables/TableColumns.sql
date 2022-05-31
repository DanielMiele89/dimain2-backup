CREATE TABLE [ChangeLog].[TableColumns] (
    [ID]         INT          IDENTITY (1, 1) NOT NULL,
    [TableName]  VARCHAR (50) NOT NULL,
    [ColumnName] VARCHAR (50) NOT NULL,
    [Datatype]   VARCHAR (20) NOT NULL,
    CONSTRAINT [PK_TableColumns] PRIMARY KEY CLUSTERED ([ID] ASC)
);

