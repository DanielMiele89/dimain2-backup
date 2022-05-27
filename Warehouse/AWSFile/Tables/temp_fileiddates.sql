CREATE TABLE [AWSFile].[temp_fileiddates] (
    [fileid]  INT  NULL,
    [mindate] DATE NULL,
    [maxdate] DATE NULL
);


GO
CREATE CLUSTERED INDEX [cix]
    ON [AWSFile].[temp_fileiddates]([fileid] ASC);

