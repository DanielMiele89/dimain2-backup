CREATE TABLE [Processing].[PackageLog_ProgressReport] (
    [EmailOrder]      INT              NOT NULL,
    [FileType]        VARCHAR (30)     NOT NULL,
    [EndSourceID]     UNIQUEIDENTIFIER NULL,
    [EmailedDateTime] DATETIME         NULL,
    CONSTRAINT [pk_Processing_PackageLog_ProgressReport] PRIMARY KEY CLUSTERED ([FileType] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [uncix_emailorder]
    ON [Processing].[PackageLog_ProgressReport]([EmailOrder] ASC);

