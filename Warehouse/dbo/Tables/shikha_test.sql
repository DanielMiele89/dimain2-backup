CREATE TABLE [dbo].[shikha_test] (
    [id]   INT           NULL,
    [test] VARCHAR (100) NULL
);




GO
GRANT INSERT
    ON OBJECT::[dbo].[shikha_test] TO [sfduser]
    AS [dbo];

