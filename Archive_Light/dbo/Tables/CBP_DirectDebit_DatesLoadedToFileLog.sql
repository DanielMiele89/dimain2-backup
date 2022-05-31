CREATE TABLE [dbo].[CBP_DirectDebit_DatesLoadedToFileLog] (
    [AWSLoadDateStart]      DATETIME NOT NULL,
    [DateValueLoadedToFile] DATE     NOT NULL,
    CONSTRAINT [PK_CBP_DirectDebit_DatesLoadedToFileLog] PRIMARY KEY CLUSTERED ([AWSLoadDateStart] ASC, [DateValueLoadedToFile] ASC)
);

